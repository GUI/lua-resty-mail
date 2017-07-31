local mail = require "resty.mail"

describe("mail", function()
  it("returns connection error (port)", function()
    local mailer = mail.new({
      host = "127.0.0.1",
      port = 1026,
    })
    local ok, err = mailer:send({
      from = "from@example.com",
      to = { "to@example.com" },
      subject = "Subject",
      text = "Message",
    })
    assert.matches("connect failure: connection refused", err, 1, true)
    assert.equal(false, ok)
  end)

  it("returns starttls error (unsupported)", function()
    local mailer = mail.new({
      host = "127.0.0.1",
      port = 1025,
      starttls = true,
    })
    local ok, err = mailer:send({
      from = "from@example.com",
      to = { "to@example.com" },
      subject = "Subject",
      text = "Message",
    })
    assert.matches("SMTP response was not successful: 500 Unrecognised command", err, 1, true)
    assert.equal(false, ok)
  end)

  it("returns ssl error (unsupported)", function()
    local mailer = mail.new({
      host = "127.0.0.1",
      port = 1025,
      ssl = true,
    })
    local ok, err = mailer:send({
      from = "from@example.com",
      to = { "to@example.com" },
      subject = "Subject",
      text = "Message",
    })
    assert.matches("sslhandshake error: handshake failed", err, 1, true)
    assert.equal(false, ok)
  end)

  it("returns missing username error", function()
    local mailer, err = mail.new({
      host = "127.0.0.1",
      port = 1025,
      password = "foo",
    })
    assert.equal("authentication requested, but missing username", err)
    assert.equal(nil, mailer)
  end)

  it("returns missing password error", function()
    local mailer, err = mail.new({
      host = "127.0.0.1",
      port = 1025,
      username = "foo",
    })
    assert.equal("authentication requested, but missing password", err)
    assert.equal(nil, mailer)
  end)

  it("returns missing username and password error", function()
    local mailer, err = mail.new({
      host = "127.0.0.1",
      port = 1025,
      auth_type = "plain",
    })
    assert.equal("authentication requested, but missing username", err)
    assert.equal(nil, mailer)
  end)
end)
