-- ESP-IDF (idf.py, CMake, ESP32 RISC-V) on top of the lang.clangd and dap.core extras.
-- nvim must be started from an activated ESP-IDF shell (get_idf in common.zsh):
-- idf.py, the GCC that clangd queries and riscv32-esp-elf-gdb come from that PATH.
--
--   clangd       Espressif's esp-clangd from ~/.espressif, with the project's build/
--                compile database; files inside ESP-IDF reuse the project's client.
--   <leader>i…   idf.py build / flash / monitor / menuconfig / reconfigure / openocd
--   <leader>dc   "ESP32-P4 (OpenOCD)": attach GDB (DAP mode) to a running OpenOCD
--
-- flash, monitor, openocd and the debug attach reset or halt the board.

local espressif = vim.fs.normalize("~/.espressif")

local function under_espressif(path)
  return path:sub(1, #espressif + 1) == espressif .. "/"
end

-- The ESP-IDF project root: the nearest directory whose CMakeLists.txt includes
-- project.cmake (component CMakeLists.txt files do not).
---@param path? string file or directory to start from (default: current buffer, else cwd)
---@return string?
local function idf_root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.uv.cwd() or "."
  end
  for dir in vim.fs.parents(vim.fs.joinpath(vim.fs.normalize(path), "x")) do
    local f = io.open(dir .. "/CMakeLists.txt", "r")
    if f then
      local text = f:read("*a")
      f:close()
      if text:find("project.cmake", 1, true) then
        return dir
      end
    end
  end
end

-- Root for an idf.py key, with the checks every key needs.
---@return string?
local function idf_ready()
  if not vim.env.IDF_PATH or vim.fn.executable("idf.py") == 0 then
    vim.notify("ESP-IDF is not active: start nvim from a `get_idf` shell", vim.log.levels.WARN)
    return
  end
  local root = idf_root()
  if not root then
    vim.notify("Not in an ESP-IDF project (no CMakeLists.txt including project.cmake)", vim.log.levels.WARN)
  end
  return root
end

------------------------------------------------------------------------------
-- idf.py in Snacks terminals
------------------------------------------------------------------------------

local last = {} ---@type table<string, snacks.win>

-- Runs `idf.py <args>` in a terminal at the project root. A key's previous terminal is
-- closed first, so repeated presses do not stack windows.
---@param name string
---@param args string[]
---@param opts? snacks.terminal.Opts
local function idf(name, args, opts)
  local root = idf_ready()
  if not root then
    return
  end
  if last[name] and last[name]:buf_valid() then
    last[name]:close()
  end
  local cmd = vim.list_extend({ "idf.py" }, args)
  last[name] = Snacks.terminal.open(
    cmd,
    vim.tbl_deep_extend("force", { cwd = root, win = { position = "bottom", height = 0.35 } }, opts or {})
  )
end

-- GCC's "file:line:col: error: msg" lines → quickfix. Paths ninja prints relative are
-- relative to build/.
---@param lines string[]
---@param root string
local function build_errors_to_qf(lines, root)
  local items = {}
  for _, line in ipairs(lines) do
    local file, lnum, col, kind, msg = line:match("^(.-):(%d+):(%d+): (%l[%l ]*): (.*)$")
    if file and (kind == "error" or kind == "fatal error") then
      if not file:match("^/") then
        file = vim.fs.normalize(vim.fs.joinpath(root, "build", file))
      end
      items[#items + 1] = { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = msg, type = "E" }
    end
  end
  vim.fn.setqflist({}, " ", { title = "idf.py build", items = items })
  return #items
end

-- Build in a terminal; output is also tee'd to a temp file, because a terminal buffer
-- wraps long compiler lines at the window width. On failure, errors go to quickfix.
local function build()
  local root = idf_ready()
  if not root then
    return
  end
  if last.build and last.build:buf_valid() then
    last.build:close()
  end
  local log = vim.fn.tempname()
  local term = Snacks.terminal.open({ "bash", "-c", 'set -o pipefail; idf.py build 2>&1 | tee "$0"', log }, {
    cwd = root,
    interactive = false,
    win = { position = "bottom", height = 0.35 },
  })
  last.build = term
  term:on("TermClose", function()
    local status = vim.v.event.status
    vim.schedule(function()
      local ok, lines = pcall(vim.fn.readfile, log)
      vim.fn.delete(log)
      if status == 0 then
        vim.fn.setqflist({}, " ", { title = "idf.py build", items = {} })
        vim.notify("idf.py build: ok")
        return
      end
      local n = ok and build_errors_to_qf(lines, root) or 0
      if n > 0 then
        vim.cmd("botright copen")
      end
      vim.notify(("idf.py build failed (exit %d), %d error(s) in quickfix"):format(status, n), vim.log.levels.ERROR)
    end)
  end, { buf = true })
end

-- OpenOCD stays visible in its own terminal: the same key hides and shows it, and
-- Ctrl-C in it (or closing it) stops OpenOCD and frees the USB-JTAG device.
local function openocd()
  local root = idf_ready()
  if root then
    Snacks.terminal.toggle({ "idf.py", "openocd" }, {
      cwd = root,
      interactive = false,
      win = { position = "bottom", height = 0.25 },
    })
  end
end

------------------------------------------------------------------------------
-- GDB (DAP mode) over OpenOCD
------------------------------------------------------------------------------

-- Is something listening on the TCP port? Asked of the OS, not by connecting: a
-- connection to OpenOCD's GDB port counts as a GDB attach, which halts the CPU.
---@return boolean? listening, nil when it cannot be told
local function listening(port)
  if vim.fn.executable("lsof") == 1 then
    return vim.system({ "lsof", "-nP", "-iTCP:" .. port, "-sTCP:LISTEN" }):wait().code == 0
  elseif vim.fn.executable("ss") == 1 then
    return (vim.system({ "ss", "-Hltn", "sport = :" .. port }):wait().stdout or "") ~= ""
  end
end

-- What ESP-IDF's build/gdbinit/connect does after `target remote`, minus its final
-- `continue` (nvim-dap continues once these are done).
local after_attach = { "monitor reset halt", "maintenance flush register-cache", "thbreak app_main" }

local function setup_dap()
  local dap = require("dap")

  dap.adapters.esp_gdb = function(cb, config)
    local root = config.cwd
    if listening(3333) == false then
      vim.notify("OpenOCD is not listening on :3333; start it with <leader>io", vim.log.levels.WARN)
      return
    end
    if vim.fn.executable("riscv32-esp-elf-gdb") == 0 then
      vim.notify("riscv32-esp-elf-gdb not on PATH: start nvim from a `get_idf` shell", vim.log.levels.WARN)
      return
    end
    cb({
      type = "executable",
      command = "riscv32-esp-elf-gdb",
      -- gdbinit files from idf.py build: ROM/bootloader symbols, source path map,
      -- FreeRTOS and driver Python helpers. remotetimeout as in gdbinit/connect.
      args = {
        "--interpreter=dap",
        "-q",
        "-ex",
        "set remotetimeout 10",
        "-x",
        "build/gdbinit/symbols",
        "-x",
        "build/gdbinit/prefix_map",
        "-x",
        "build/gdbinit/py_extensions",
      },
      options = { cwd = root },
    })
  end

  local esp32p4 = {
    type = "esp_gdb",
    request = "attach",
    name = "ESP32-P4 (OpenOCD)",
    target = "localhost:3333",
    cwd = function()
      return idf_root() or vim.uv.cwd()
    end,
    program = function()
      local root = idf_root() or vim.uv.cwd()
      local ok, desc = pcall(function()
        return vim.json.decode(table.concat(vim.fn.readfile(root .. "/build/project_description.json"), "\n"))
      end)
      if ok and desc.app_elf then
        return vim.fs.joinpath(desc.build_dir or (root .. "/build"), desc.app_elf)
      end
      return vim.fn.input("ELF: ", root .. "/build/", "file")
    end,
  }
  for _, ft in ipairs({ "c", "cpp" }) do
    local configs = dap.configurations[ft] or {}
    dap.configurations[ft] = configs
    if not vim.iter(configs):find(function(c)
      return c.name == esp32p4.name
    end) then
      table.insert(configs, 1, esp32p4)
    end
  end

  -- GDB's DAP server does `target remote` after configurationDone and reports it as a
  -- stop with reason "attach". Then: reset and halt, flush, break at app_main, go.
  dap.listeners.after.event_stopped.esp_idf = function(session, body)
    if session.config.type ~= "esp_gdb" or body.reason ~= "attach" then
      return
    end
    local function run(i)
      if i > #after_attach then
        return session:request("continue", { threadId = body.threadId or 1 }, function() end)
      end
      session:request("evaluate", { expression = after_attach[i], context = "repl" }, function(err)
        if err then
          vim.notify(("%s: %s"):format(after_attach[i], err.message or vim.inspect(err)), vim.log.levels.ERROR)
          return
        end
        run(i + 1)
      end)
    end
    run(1)
  end
end

------------------------------------------------------------------------------

return {
  -- clangd: esp-clangd + the project's compile database
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local clangd = opts.servers and opts.servers.clangd
      if type(clangd) ~= "table" then
        return
      end
      clangd.mason = false -- Mason's clangd would shadow esp-clangd on PATH

      local base = vim.deepcopy(clangd.cmd or { "clangd" })
      table.remove(base, 1)
      base = vim.tbl_filter(function(a)
        return not a:match("^%-%-fallback%-style=")
      end, base)
      -- no .clang-format → no reformatting (instead of 2-space LLVM style)
      table.insert(base, "--fallback-style=none")
      -- only Espressif's RISC-V GCC may be run to learn its include paths
      table.insert(
        base,
        "--query-driver=" .. espressif .. "/tools/riscv32-esp-elf/*/riscv32-esp-elf/bin/riscv32-esp-elf-*"
      )

      clangd.cmd = function(dispatchers, config)
        local bins = vim.fn.glob(espressif .. "/tools/esp-clangd/*/esp-clangd/bin/clangd", false, true)
        table.sort(bins)
        local cmd = { bins[#bins] or "clangd" }
        vim.list_extend(cmd, base)
        -- one database for the project and for the ESP-IDF sources it compiles
        local root = config.root_dir
        if root and vim.uv.fs_stat(root .. "/build/compile_commands.json") then
          table.insert(cmd, "--compile-commands-dir=" .. root .. "/build")
        end
        return vim.lsp.rpc.start(cmd, dispatchers, {
          cwd = config.cmd_cwd,
          env = config.cmd_env,
          detached = config.detached,
        })
      end

      local markers = clangd.root_markers or { "compile_commands.json", ".git" }
      clangd.root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        -- gd into ESP-IDF: stay in the project's clangd instead of starting one rooted
        -- in the ESP-IDF tree, which has no compile database
        if under_espressif(fname) then
          for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
            if client.root_dir and not under_espressif(client.root_dir) then
              return on_dir(client.root_dir)
            end
          end
        end
        -- nil (no root) starts clangd for the single file, as root_markers would
        on_dir(idf_root(fname) or vim.fs.root(bufnr, markers))
      end
    end,
  },

  -- idf.py keys
  {
    "folke/snacks.nvim",
    -- stylua: ignore
    keys = {
      { "<leader>ib", build, desc = "Build (errors → quickfix)" },
      { "<leader>if", function() idf("flash", { "flash" }) end, desc = "Flash (resets board)" },
      { "<leader>im", function() idf("monitor", { "monitor" }) end, desc = "Monitor (Ctrl-] quits)" },
      { "<leader>iF", function() idf("flash", { "flash", "monitor" }) end, desc = "Flash + Monitor" },
      { "<leader>ic", function() idf("menuconfig", { "menuconfig" }, { win = { position = "float", width = 0.9, height = 0.9 } }) end, desc = "Menuconfig" },
      { "<leader>ir", function() idf("reconfigure", { "reconfigure" }, { interactive = false }) end, desc = "Reconfigure" },
      { "<leader>io", openocd, desc = "OpenOCD (toggle; halts CPU)" },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>i", group = "idf", icon = { icon = "", color = "red" } } } },
  },

  -- GDB debugging over OpenOCD; the lang.clangd extra's codelldb configs stay after it
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      setup_dap()
    end,
  },
}
