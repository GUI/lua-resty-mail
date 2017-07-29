local message = require "resty.mail.message"

describe("message get_body", function()
  it("message-id uses from host", function()
    local msg = message.new({
      from = "foo@example.com",
    })
    assert.matches("Message%-ID: <.+@example.com.mail>", msg:get_body_string())
  end)

  it("message-id defaults to localhost for unparsable from", function()
    local msg = message.new({
      from = "foo",
    })
    assert.matches("Message%-ID: <.+@localhost.localdomain>", msg:get_body_string())
  end)

  it("message-id defaults to localhost", function()
    local msg = message.new()
    assert.matches("Message%-ID: <.+@localhost.localdomain>", msg:get_body_string())
  end)
end)
