local message = require "resty.mail.message"

describe("message get_from_address", function()
  it("returns address", function()
    local msg = message.new({
      from = "foo@example.com",
    })
    assert.equal("foo@example.com", msg:get_from_address())
  end)

  it("extracts address from name", function()
    local msg = message.new({
      from = "Foobar <foo@example.com>",
    })
    assert.equal("foo@example.com", msg:get_from_address())
  end)

  it("extracts address from name and spaces", function()
    local msg = message.new({
      from = "Foobar  < foo@example.com > ",
    })
    assert.equal("foo@example.com", msg:get_from_address())
  end)

  it("returns nil when not present", function()
    local msg = message.new()
    assert.equal(nil, msg:get_from_address())
  end)
end)
