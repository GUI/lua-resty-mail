local cjson = require "cjson"
local http = require "resty.http"
local mail = require "resty.mail"

describe("mail integration internal #integration_internal", function()
  before_each(function()
    local httpc = http.new()
    local res, err = httpc:request_uri("http://127.0.0.1:8025/api/v1/messages", {
      method = "DELETE",
    })
    assert.equal(nil, err)
    assert.equal(200, res.status)
  end)

  it("sends example mail", function()
    local mailer = mail.new({
      host = "127.0.0.1",
      port = 1025,
    })
    local ok, err = mailer:send({
      from = "From <from@example.com>",
      reply_to = "Reply <reply@example.com>",
      to = { "To <to@example.com>", "to2@example.com" },
      cc = { "Cc <cc@example.com>", "cc2@example.com" },
      bcc = { "Bcc <bcc@example.com>", "bcc2@example.com" },
      subject = "Subject",
      text = "Plain Text",
      html = "<p>HTML Text</p>",
      headers = {
        ["X-Foo"] = "bar",
        ["X-Bar"] = "baz",
      },
      attachments = {
        {
          filename = "foo.txt",
          content_type = "text/plain",
          content = "Hello, World (attachment).",
        },
        {
          filename = "foo.txt",
          content_type = "text/plain",
          content = "Hello, World (inline).",
          disposition = "inline",
          content_id = "custom_content_id",
        },
      },
    })
    assert.equal(nil, err)
    assert.equal(true, ok)

    local httpc = http.new()
    local res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/messages")
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    local data = cjson.decode(res.body)
    assert.equal(1, #data["messages"])
    local msg = data["messages"][1]

    res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/message/" .. msg["ID"])
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    msg = cjson.decode(res.body)

    res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/message/" .. msg["ID"] .. "/headers")
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    local headers = cjson.decode(res.body)

    res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/message/" .. msg["ID"] .. "/raw")
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    local raw = res.body

    local attachments = {}
    for _, item in ipairs(msg["Attachments"]) do
      res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/message/" .. msg["ID"] .. "/part/" .. item["PartID"])
      assert.equal(nil, http_err)
      assert.equal(200, res.status)
      local attachment = res.body
      table.insert(attachments, attachment)
    end

    local inlines = {}
    for _, item in ipairs(msg["Inline"]) do
      res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/message/" .. msg["ID"] .. "/part/" .. item["PartID"])
      assert.equal(nil, http_err)
      assert.equal(200, res.status)
      local inline = res.body
      table.insert(inlines, inline)
    end

    -- From
    assert.equal("From", msg["From"]["Name"])
    assert.equal("from@example.com", msg["From"]["Address"])

    -- Recipients
    assert.equal("To", msg["To"][1]["Name"])
    assert.equal("to@example.com", msg["To"][1]["Address"])
    assert.equal("", msg["To"][2]["Name"])
    assert.equal("to2@example.com", msg["To"][2]["Address"])
    assert.equal("Cc", msg["Cc"][1]["Name"])
    assert.equal("cc@example.com", msg["Cc"][1]["Address"])
    assert.equal("", msg["Cc"][2]["Name"])
    assert.equal("cc2@example.com", msg["Cc"][2]["Address"])
    assert.equal("", msg["Bcc"][1]["Name"])
    assert.equal("bcc2@example.com", msg["Bcc"][1]["Address"])
    assert.equal("", msg["Bcc"][2]["Name"])
    assert.equal("bcc@example.com", msg["Bcc"][2]["Address"])

    -- Headers
    assert.same({ "Cc <cc@example.com>,cc2@example.com" }, headers["Cc"])
    assert.equal(1, #headers["Content-Type"])
    assert.matches("multipart/mixed; boundary=\"", headers["Content-Type"][1], 1, true)
    assert.equal(1, #headers["Date"])
    assert.same({ "From <from@example.com>" }, headers["From"])
    assert.same({ "1.0" }, headers["Mime-Version"])
    assert.equal(1, #headers["Message-Id"])
    assert.equal(1, #headers["Received"])
    assert.same({ "Reply <reply@example.com>" }, headers["Reply-To"])
    assert.same({ "<from@example.com>" }, headers["Return-Path"])
    assert.same({ "Subject" }, headers["Subject"])
    assert.same({ "To <to@example.com>,to2@example.com" }, headers["To"])
    assert.same({ "baz" }, headers["X-Bar"])
    assert.same({ "bar" }, headers["X-Foo"])
    -- Note, these `Bcc` headers aren't actually sent over the wire in the SMTP
    -- message (as tested by `message_get_body_spec.lua`), but instead these
    -- `Bcc` headers are faked by Mailpit:
    -- https://github.com/axllent/mailpit/commit/9c8329a05cef34b228a501cb14b3a9a346189905
    -- So if this behavior changes in the future, that's okay, this just
    -- reflects current behavior.
    assert.same({ "bcc2@example.com, bcc@example.com" }, headers["Bcc"])

    -- Content
    assert.equal("Plain Text\n--\nHello, World (inline).", msg["Text"])
    assert.equal("<p>HTML Text</p>", msg["HTML"])

    -- MIME content
    assert.matches("This is a multi-part message in MIME format.", raw, 1, true)
    assert.matches("multipart/mixed; boundary=\"", raw, 1, true)
    assert.matches("multipart/alternative; boundary=\"", raw, 1, true)
    assert.matches("Content-Transfer-Encoding: base64", raw, 1, true)
    assert.matches("Content-Type: text/plain; charset=utf-8", raw, 1, true)
    assert.matches("Content-Type: text/html; charset=utf-8", raw, 1, true)
    assert.matches("UGxhaW4gVGV4dA==", raw, 1, true)

    -- Attachments
    assert.equal(1, #msg["Attachments"])
    assert.equal(1, #attachments)
    local part = msg["Attachments"][1]
    assert.matches("@localhost.localdomain", part["ContentID"], 1, true)
    assert.same("foo.txt", part["FileName"])
    assert.same("text/plain", part["ContentType"])
    assert.equal("Hello, World (attachment).", attachments[1])

    assert.equal(1, #msg["Inline"])
    assert.equal(1, #inlines)
    part = msg["Inline"][1]
    assert.matches("custom_content_id", part["ContentID"], 1, true)
    assert.same("foo.txt", part["FileName"])
    assert.same("text/plain", part["ContentType"])
    assert.equal("Hello, World (inline).", inlines[1])
  end)

  it("sends bcc-only mail", function()
    local mailer = mail.new({
      host = "127.0.0.1",
      port = 1025,
    })
    local ok, err = mailer:send({
      from = "From <from@example.com>",
      bcc = { "bcc@example.com" },
      subject = "Subject",
      text = "Plain Text",
    })
    assert.equal(nil, err)
    assert.equal(true, ok)

    local httpc = http.new()
    local res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/messages")
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    local data = cjson.decode(res.body)
    assert.equal(1, #data["messages"])
    local msg = data["messages"][1]

    res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/message/" .. msg["ID"])
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    msg = cjson.decode(res.body)

    res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v1/message/" .. msg["ID"] .. "/headers")
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    local headers = cjson.decode(res.body)

    -- From
    assert.equal("From", msg["From"]["Name"])
    assert.equal("from@example.com", msg["From"]["Address"])

    -- Recipients
    assert.same({}, msg["To"])
    assert.same({}, msg["Cc"])
    assert.equal("", msg["Bcc"][1]["Name"])
    assert.equal("bcc@example.com", msg["Bcc"][1]["Address"])

    -- Headers
    assert.equal(nil, headers["To"])
    assert.equal(nil, headers["Cc"])
    assert.same({ "Subject" }, headers["Subject"])
    -- Note, these `Bcc` headers aren't actually sent over the wire in the SMTP
    -- message (as tested by `message_get_body_spec.lua`), but instead these
    -- `Bcc` headers are faked by Mailpit:
    -- https://github.com/axllent/mailpit/commit/9c8329a05cef34b228a501cb14b3a9a346189905
    -- So if this behavior changes in the future, that's okay, this just
    -- reflects current behavior.
    assert.same({ "bcc@example.com", "" }, headers["Bcc"])

    -- Content
    assert.equal("Plain Text", msg["Text"])
    assert.equal("", msg["HTML"])
  end)
end)
