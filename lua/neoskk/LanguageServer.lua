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

---@alias Method fun(params: table?, callback: fun(err: lsp.ResponseError|nil, result: any)?)

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
---@return LanguageServer
function LanguageServer.new(logger, dispatchers)
  local self = setmetatable({
    logger = logger,
    dispatchers = dispatchers,
    message_id = 1,
    stopped = false,
    request_map = {
      [vim.lsp.protocol.Methods.textDocument_hover] = function(params, callback)
        local neoskk = require "neoskk"
        neoskk.instance.dict:lsp_hover(params, callback)
      end,
      [vim.lsp.protocol.Methods.textDocument_completion] = function(params, callback)
        local neoskk = require "neoskk"
        neoskk.instance.dict:lsp_completion(params, callback)
      end,
    },
  }, LanguageServer)
  return self
end

function LanguageServer:stop()
  self.stopped = true
end

---@param root_dir string
function LanguageServer.launch(root_dir)
  local logger = LanguageServerLogger.new()
  local config = {
    name = NAME,
    root_dir = root_dir,
    ---@param dispatchers vim.lsp.rpc.Dispatchers
    ---@return vim.lsp.rpc.PublicClient
    cmd = function(dispatchers)
      local server = LanguageServer.new(logger, dispatchers)
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
---@param callback fun(err: lsp.ResponseError|nil, result: any)?
function LanguageServer:_handle(method, params, callback, is_notify)
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
    if self.dispatchers.on_exit then
      self.dispatchers.on_exit(0, 0)
    end
  else
    local request_method = self.request_map[method]
    if request_method then
      request_method(params, callback)
    end

    if not is_notify and not params._null_ls_handled then
      -- result for not processed request
      send()
    end
  end
end

---@param method vim.lsp.protocol.Method|string LSP method name.
---@param params table? LSP request params.
---@param callback fun(err: lsp.ResponseError|nil, result: any)
---@param notify_callback fun(message_id: integer)?
function LanguageServer:request(method, params, callback, notify_callback)
  self.logger:trace("received LSP request for method " .. method)

  -- clear pending requests from client object
  self:_handle(method, params, callback)
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
  if method == vim.lsp.protocol.Methods.textDocument_didClose then
  end

  self.logger:trace("received LSP notification for method " .. method)
  return self:_handle(method, params, nil, true)
end

return LanguageServer
