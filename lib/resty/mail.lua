local message = require "resty.mail.message"
local smtp = require "resty.mail.smtp"

local _M = {}

function _M.new(options)
  if not options then
    options = {}
  end

  if not options["host"] then
    options["host"] = "localhost"
  end

  if not options["port"] then
    options["port"] = 25
  end

  return setmetatable({ options = options }, { __index = _M })
end

function _M.send(self, data)
  return smtp.send(self, message.new(data))
end

return _M
