local c = require "null-ls.config"
local u = require "null-ls.utils"

--- Retrieves the path of the logfile
---@return string path path of the logfile
local function get_log_path()
  return u.path.join(vim.fn.stdpath "cache" --[[@as string]], "neoskk-ls.log")
end

---@alias Method fun(params: table?, callback: fun(err: lsp.ResponseError|nil, result: any)?)

---@class LanguageServer
---@field message_id integer
---@field stopped boolean
---@field __notify_fmt fun(msg: string)
---@field request_map table<string, Method>
local LanguageServer = {}
LanguageServer.__index = LanguageServer

LanguageServer.capabilities = {
  -- completionProvider = {
  --   -- FIXME: How do we decide what trigger characters are?
  --   triggerCharacters = { ".", ":", "-" },
  --   allCommitCharacters = {},
  --   resolveProvider = false,
  --   completionItem = {
  --     labelDetailsSupport = true,
  --   },
  -- },
  -- textDocumentSync = {
  --   change = 1, -- prompt LSP client to send full document text on didOpen and didChange
  --   openClose = true,
  --   save = { includeText = true },
  -- },
  hoverProvider = true,
}

---@return LanguageServer
function LanguageServer.new()
  local self = setmetatable({
    message_id = 1,
    stopped = false,
    logger = require("plenary.log").new {
      plugin = "neoskk-ls",
      level = "trace",
      -- use_console = false,
      use_console = "async",
      info_level = 4,
      use_file = true,
      outfile = get_log_path(),
    },
    request_map = {
      [vim.lsp.protocol.Methods.textDocument_hover] = function(params, callback)
        local neoskk = require "neoskk"
        neoskk.instance.dict:lsp_hover(params, callback)
      end,
    },
  }, LanguageServer)

  return self
end

--- Retrieves the path of the logfile
---@return string path path of the logfile
function LanguageServer:get_log_path()
  return get_log_path()
end

--- Adds a log entry using Plenary.log
---@param msg any
---@param level string [same as vim.log.log_levels]
function LanguageServer:add_entry(msg, level)
  local cfg = c.get()
  if not self.__notify_fmt then
    self.__notify_fmt = function(m)
      return string.format(cfg.notify_format, m)
    end
  end

  local fmt_msg = self.logger[level]
  ---@cast fmt_msg fun(msg: string)
  fmt_msg(msg)
end

---Add a log entry at TRACE level
---@param msg any
function LanguageServer:log_trace(msg)
  self:add_entry(msg, "trace")
end

---Add a log entry at DEBUG level
---@param msg any
function LanguageServer:debug(msg)
  self:add_entry(msg, "debug")
end

---Add a log entry at INFO level
---@param msg any
function LanguageServer:info(msg)
  self:add_entry(msg, "info")
end

---Add a log entry at WARN level
---@param msg any
function LanguageServer:warn(msg)
  self:add_entry(msg, "warn")
  vim.schedule(function()
    vim.notify(self.__notify_fmt(msg), vim.log.levels.WARN, default_notify_opts)
  end)
end

---Add a log entry at ERROR level
---@param msg any
function LanguageServer:error(msg)
  self:add_entry(msg, "error")
  vim.schedule(function()
    vim.notify(self.__notify_fmt(msg), vim.log.levels.ERROR, default_notify_opts)
  end)
end

function LanguageServer:try_add()
  local bufnr = vim.api.nvim_get_current_buf()
  local root_dir = "/"

  ---@param dispatchers vim.lsp.rpc.Dispatchers
  ---@return vim.lsp.rpc.PublicClient
  local function start(dispatchers) ---@param method vim.lsp.protocol.Method|string LSP method name.
    ---@param params table? LSP request params.
    ---@param callback fun(err: lsp.ResponseError|nil, result: any)?
    local function handle(method, params, callback, is_notify)
      params = params or {}
      callback = callback and vim.schedule_wrap(callback)
      self.message_id = self.message_id + 1

      if type(params) ~= "table" then
        params = { params }
      end

      params.method = method
      params.client_id = require("null-ls.client").get_id()

      local send = function(result)
        if callback then
          callback(nil, result)
        end
      end

      if method == vim.lsp.protocol.Methods.initialize then
        send { capabilities = LanguageServer.capabilities }
      elseif method == vim.lsp.protocol.Methods.shutdown then
        self.stopped = true
        send()
      elseif method == vim.lsp.protocol.Methods.EXIT then
        if dispatchers.on_exit then
          dispatchers.on_exit(0, 0)
        end
      else
        -- unknown
        local request_method = self.request_map[method]
        if request_method then
          request_method(params, callback)
        end

        if is_notify then
        else
          if not params._null_ls_handled then
            send()
          end
        end
      end
    end

    ---@param method vim.lsp.protocol.Method|string LSP method name.
    ---@param params table? LSP request params.
    ---@param callback fun(err: lsp.ResponseError|nil, result: any)
    ---@param notify_callback fun(message_id: integer)?
    local function request(method, params, callback, notify_callback)
      self:log_trace("received LSP request for method " .. method)

      -- clear pending requests from client object
      handle(method, params, callback)
      if notify_callback then
        -- copy before scheduling to make sure it hasn't changed
        local id_to_clear = self.message_id
        vim.schedule(function()
          notify_callback(id_to_clear)
        end)
      end

      return true, self.message_id
    end

    ---@param method string LSP method name.
    ---@param params table? LSP request params.
    local function notify(method, params)
      if method == vim.lsp.protocol.Methods.textDocument_didClose then
      end

      self:log_trace("received LSP notification for method " .. method)
      return handle(method, params, nil, true)
    end

    return {
      request = request,
      notify = notify,
      is_closing = function()
        return self.stopped
      end,
      terminate = function()
        -- cache._reset()
        self.stopped = true
      end,
    }
  end

  -- local id = M.start_client(root_dir)
  local config = {
    name = "neoskk-ls",
    root_dir = root_dir,
    cmd = start, -- pass callback to create rpc client
  }

  -- self:log_trace "starting null-ls client"
  local id = vim.lsp.start(config)
  if not id then
    -- log:error(string.format("failed to start null-ls client with config: %s", vim.inspect(config)))
  end

  -- return id
  if not id then
    -- if cb then
    --   cb(false)
    -- end
    return
  end

  local did_attach = vim.lsp.buf_is_attached(bufnr, id) or vim.lsp.buf_attach_client(bufnr, id)
  if not did_attach then
    -- log:warn(string.format("failed to attach buffer %d", bufnr))
  end

  -- if cb then
  --   cb(did_attach)
  -- end
end

return LanguageServer
