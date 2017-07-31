local message = require "resty.mail.message"

describe("message get_recipient_addresses", function()
  it("returns to, cc, bcc addresses", function()
    local msg = message.new({
      to = { "a@example.com", "b@example.com" },
      cc = { "c@example.com", "d@example.com" },
      bcc = { "e@example.com", "f@example.com" },
    })
    assert.same({
      "a@example.com",
      "b@example.com",
      "c@example.com",
      "d@example.com",
      "e@example.com",
      "f@example.com",
    }, msg:get_recipient_addresses())
  end)

  it("returns only unique addresses", function()
    local msg = message.new({
      to = { "a@example.com", "a@example.com" },
      cc = { "a@example.com", "a@example.com" },
      bcc = { "a@example.com", "a@example.com" },
    })
    assert.same({ "a@example.com" }, msg:get_recipient_addresses())
  end)

  it("extracts addresses from name and spaces", function()
    local msg = message.new({
      to = { "Foo <a@example.com>" },
      cc = { "Bar  < b@example.com >" },
      bcc = { "Baz <c@example.com>" },
    })
    assert.same({
      "a@example.com",
      "b@example.com",
      "c@example.com",
    }, msg:get_recipient_addresses())
  end)

  it("returns empty list when not present", function()
    local msg = message.new()
    assert.same({}, msg:get_recipient_addresses())
  end)
end)
