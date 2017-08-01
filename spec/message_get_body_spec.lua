local message = require "resty.mail.message"

describe("message get_body", function()
  it("contains message-id, which uses 'from' host", function()
    local msg = message.new({
      from = "foo@example.com",
    })
    assert.matches("Message%-ID: <.+@example.com.mail>", msg:get_body_string())
  end)

  it("contains message-id, which uses 'from' host with name", function()
    local msg = message.new({
      from = "Foo <foo@example.com>",
    })
    assert.matches("Message%-ID: <.+@example.com.mail>", msg:get_body_string())
  end)

  it("contains message-id, which defaults to localhost for unparsable 'from'", function()
    local msg = message.new({
      from = "foo",
    })
    assert.matches("Message%-ID: <.+@localhost.localdomain>", msg:get_body_string())
  end)

  it("contains message-id, which defaults to localhost", function()
    local msg = message.new()
    assert.matches("Message%-ID: <.+@localhost.localdomain>", msg:get_body_string())
  end)

  it("contains date, which always uses rfc 2822 english locale", function()
    local orig_locale = os.setlocale()
    assert(os.setlocale("fr_FR"))
    assert.equal("ven., 28 juil. 2017", os.date("!%a, %d %b %Y", 1501211178))

    local msg = message.new()
    -- Since the date output will be the current date, check to make sure the
    -- format matches the expected English output (which we can test for, since
    -- the french locale will have extra characters).
    assert.matches("Date: [A-Z][a-z][a-z], %d%d [A-Z][a-z][a-z] %d%d%d%d %d%d:%d%d:%d%d [+-]%d%d%d%d", msg:get_body_string())

    assert(os.setlocale(orig_locale))
  end)

  it("wraps the lines in base64 encoded bodies", function()
    local msg = message.new({
      text = "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789",
      html = "<p>abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789</p>",
    })
    local body = msg:get_body_string()
    local boundary = ngx.re.match(body, 'Content-Type: multipart/alternative; boundary="([^"]+)"')[1]
    assert.matches("--" .. boundary .. "\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\nYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW5vcHFyc3R1\r\ndnd4eXowMTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5YWJjZGVm\r\nZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5\r\n--" .. boundary .. "\r\nContent-Type: text/html; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\nPHA+YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW5vcHFy\r\nc3R1dnd4eXowMTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5YWJj\r\nZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5PC9wPg==\r\n--" .. boundary .. "--", body, 1, true)
  end)

  it("supports custom headers", function()
    local msg = message.new({
      headers = {
        ["X-Foo"] = "bar",
      },
    })
    assert.matches("X-Foo: bar\r\n", msg:get_body_string(), 1, true)
  end)

  it("supports attachments", function()
    local msg = message.new({
      attachments = {
        {
          filename = "foobar.txt",
          content_type = "text/plain",
          content = "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789",
        },
      },
    })
    local body = msg:get_body_string()
    local boundary = ngx.re.match(body, 'Content-Type: multipart/mixed; boundary="([^"]+)"')[1]
    local content_id = ngx.re.match(body, "Content-ID: (<[^>]+>)")[1]
    assert.matches("--" .. boundary .. "\r\nContent-Type: text/plain\r\nContent-Transfer-Encoding: base64\r\nContent-Disposition: attachment; filename=\"=?utf-8?B?Zm9vYmFyLnR4dA==?=\"\r\nContent-ID: " .. content_id .. "\r\n\r\nYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW5vcHFyc3R1\r\ndnd4eXowMTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5YWJjZGVm\r\nZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5\r\n--" .. boundary .. "--", body, 1, true)
  end)
end)
