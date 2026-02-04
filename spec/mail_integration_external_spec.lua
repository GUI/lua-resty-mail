local mail = require "resty.mail"

describe("mail integration external #integration_external", function()
  local username, password, recipient
  setup(function()
    username = os.getenv("MAILGUN_USERNAME") or error("Must set MAILGUN_USERNAME environment variable")
    password = os.getenv("MAILGUN_PASSWORD") or error("Must set MAILGUN_PASSWORD environment variable")
    recipient = os.getenv("MAILGUN_RECIPIENT") or error("Must set MAILGUN_RECIPIENT environment variable")
  end)

  it("sends starttls enabled mail", function()
    local mailer, mailer_err = mail.new({
      host = "smtp.mailgun.org",
      port = 587,
      username = username,
      password = password,
      starttls = true,
    })
    assert.equal(nil, mailer_err)
    local ok, err = mailer:send({
      from = "foo@example.com",
      to = { recipient },
      subject = "Subject",
      text = "Message",
      headers = {
        ["X-Mailgun-Drop-Message"] = "yes",
      },
    })
    assert.equal(nil, err)
    assert.equal(true, ok)
  end)

  it("sends ssl enabled mail", function()
    local mailer, mailer_err = mail.new({
      host = "smtp.mailgun.org",
      port = 465,
      username = username,
      password = password,
      ssl = true,
    })
    assert.equal(nil, mailer_err)
    local ok, err = mailer:send({
      from = "foo@example.com",
      to = { recipient },
      subject = "Subject",
      text = "Message",
      headers = {
        ["X-Mailgun-Drop-Message"] = "yes",
      },
    })
    assert.equal(nil, err)
    assert.equal(true, ok)
  end)

  it("sends login authenticated mail", function()
    local mailer, mailer_err = mail.new({
      host = "smtp.mailgun.org",
      port = 587,
      username = username,
      password = password,
      auth_type = "login",
    })
    assert.equal(nil, mailer_err)
    local ok, err = mailer:send({
      from = "foo@example.com",
      to = { recipient },
      subject = "Subject",
      text = "Message",
      headers = {
        ["X-Mailgun-Drop-Message"] = "yes",
      },
    })
    assert.equal(nil, err)
    assert.equal(true, ok)
  end)

  it("rejects starttls when ssl_verify is enabled and no system certs are configured", function()
    local mailer, mailer_err = mail.new({
      host = "smtp.mailgun.org",
      port = 587,
      username = username,
      password = password,
      starttls = true,
      ssl_verify = true,
    })
    assert.equal(nil, mailer_err)
    local ok, err = mailer:send({
      from = "foo@example.com",
      to = { recipient },
      subject = "Subject",
      text = "Message",
      headers = {
        ["X-Mailgun-Drop-Message"] = "yes",
      },
    })
    assert.equal(false, ok)
    assert.matches("sslhandshake error: 19: self-signed certificate in certificate chain", err, 1, true)
  end)

  it("rejects ssl when ssl_verify is enabled and no system certs are configured", function()
    local mailer, mailer_err = mail.new({
      host = "smtp.mailgun.org",
      port = 465,
      username = username,
      password = password,
      ssl = true,
      ssl_verify = true,
    })
    assert.equal(nil, mailer_err)
    local ok, err = mailer:send({
      from = "foo@example.com",
      to = { recipient },
      subject = "Subject",
      text = "Message",
      headers = {
        ["X-Mailgun-Drop-Message"] = "yes",
      },
    })
    assert.equal(false, ok)
    assert.matches("sslhandshake error: 19: self-signed certificate in certificate chain", err, 1, true)
  end)
end)
