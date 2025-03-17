local NAME = "neoskk-ls"

---@type lsp.ServerCapabilities
local CAPABILITIES = {
  completionProvider = {
    -- triggerCharacters = { "▽" },
  },
  -- textDocumentSync = {
  --   change = 1, -- prompt LSP client to send full document text on didOpen and didChange
  --   openClose = true,
  --   save = { includeText = true },
  -- },
  hoverProvider = true,
}

---@class LanguageServerLogger
---@field logger table
local LanguageServerLogger = {}
LanguageServerLogger.__index = LanguageServerLogger

--- Retrieves the path of the logfile
---@return string path path of the logfile
function LanguageServerLogger.get_log_path()
  return vim.fs.joinpath(vim.fn.stdpath "cache" --[[@as string]], "neoskk-ls.log")
end

---@return LanguageServerLogger
function LanguageServerLogger.new()
  local self = setmetatable({
    logger = require("plenary.log").new {
      plugin = NAME,
      level = "trace",
      -- use_console = false,
      use_console = "async",
      info_level = 4,
      use_file = true,
      outfile = LanguageServerLogger.get_log_path(),
    },
  }, LanguageServerLogger)
  self:trace "starting neoskk LanguageServerLogger"
  return self
end

--- Adds a log entry using Plenary.log
---@param msg any
---@param level string [same as vim.log.log_levels]
function LanguageServerLogger:add_entry(msg, level)
  local fmt_msg = self.logger[level]
  ---@cast fmt_msg fun(msg: string)
  fmt_msg(msg)
end

---Add a log entry at TRACE level
---@param msg any
function LanguageServerLogger:trace(msg)
  self:add_entry(msg, "trace")
end

---Add a log entry at DEBUG level
---@param msg any
function LanguageServerLogger:debug(msg)
  self:add_entry(msg, "debug")
end

---Add a log entry at INFO level
---@param msg any
function LanguageServerLogger:info(msg)
  self:add_entry(msg, "info")
end

---Add a log entry at WARN level
---@param msg any
function LanguageServerLogger:warn(msg)
  self:add_entry(msg, "warn")
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.WARN)
  end)
end

---Add a log entry at ERROR level
---@param msg any
function LanguageServerLogger:error(msg)
  self:add_entry(msg, "error")
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.ERROR)
  end)
end

---@alias Method fun(params: table?)[lsp.ResponseError?, any]

---@class LanguageServer
---@field logger LanguageServerLogger
---@field dispatchers vim.lsp.rpc.Dispatchers
---@field message_id integer
---@field stopped boolean
---@field request_map table<string, Method>
local LanguageServer = {}
LanguageServer.__index = LanguageServer
LanguageServer.server_name = NAME
LanguageServer.capabilities = CAPABILITIES

--- Retrieves the path of the logfile
---@return string path path of the logfile
function LanguageServer.get_log_path()
  return LanguageServerLogger.get_log_path()
end

---@param logger LanguageServerLogger
---@param dispatchers vim.lsp.rpc.Dispatchers
---@params request_map table<string, Method>
---@return LanguageServer
function LanguageServer.new(logger, dispatchers, request_map)
  local self = setmetatable({
    logger = logger,
    dispatchers = dispatchers,
    message_id = 1,
    stopped = false,
    request_map = request_map,
  }, LanguageServer)
  return self
end

function LanguageServer:stop()
  self.stopped = true
end

---@param root_dir string
---@param request_map table<string, Method>
function LanguageServer.launch(root_dir, request_map)
  local logger = LanguageServerLogger.new()
  local config = {
    name = NAME,
    root_dir = root_dir,
    ---@param dispatchers vim.lsp.rpc.Dispatchers
    ---@return vim.lsp.rpc.PublicClient
    cmd = function(dispatchers)
      local server = LanguageServer.new(logger, dispatchers, request_map)
      return {
        request = function(...)
          server:request(...)
        end,
        notify = function(...)
          server:notify(...)
        end,
        is_closing = function()
          return server.stopped
        end,
        terminate = function()
          server:stop()
        end,
      }
    end,
  }
  local id = vim.lsp.start(config)
  if not id then
    logger:error(string.format("failed to start neoskk client with config: %s", vim.inspect(config)))
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local did_attach = vim.lsp.buf_is_attached(bufnr, id) or vim.lsp.buf_attach_client(bufnr, id)
  if not did_attach then
    logger:warn(string.format("failed to attach buffer %d", bufnr))
    return
  end
end

---@param method vim.lsp.protocol.Method|string LSP method name.
---@param params table? LSP request params.
---@return lsp.ResponseError? err
---@return any? result
function LanguageServer:_handle(method, params)
  self.message_id = self.message_id + 1
  if method == vim.lsp.protocol.Methods.initialize then
    return nil, { capabilities = LanguageServer.capabilities }
  elseif method == vim.lsp.protocol.Methods.shutdown then
    self.stopped = true
    return
  elseif method == vim.lsp.protocol.Methods.EXIT then
    if self.dispatchers.on_exit then
      self.dispatchers.on_exit(0, 0)
    end
  else
    local request_method = self.request_map[method]
    if request_method then
      return request_method(params)
    end
  end
end

---@param method vim.lsp.protocol.Method|string LSP method name.
---@param params table? LSP request params.
---@param callback fun(err: lsp.ResponseError|nil, result: any)
---@param notify_callback fun(message_id: integer)?
function LanguageServer:request(method, params, callback, notify_callback)
  self.logger:trace("received LSP request for method " .. method)

  local err, res = self:_handle(method, params)
  -- vim.schedule_wrap(callback)(err, res)
  callback(err, res)

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
function LanguageServer:notify(method, params)
  self.logger:trace("received LSP notification for method " .. method)
  self:_handle(method, params)
end

return LanguageServer
