local cjson = require "cjson"
local http = require "resty.http"
local mail = require "resty.mail"
local tablex = require "pl.tablex"

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
          content = "Hello, World.",
        },
        {
          filename = "foo.txt",
          content_type = "text/plain",
          content = "Hello, World.",
          disposition = "inline",
          content_id = "custom_content_id",
        },
      },
    })
    assert.equal(nil, err)
    assert.equal(true, ok)

    local httpc = http.new()
    local res, http_err = httpc:request_uri("http://127.0.0.1:8025/api/v2/messages")
    assert.equal(nil, http_err)
    assert.equal(200, res.status)
    local data = cjson.decode(res.body)
    assert.equal(1, #data["items"])
    local msg = data["items"][1]

    -- From
    assert.equal("from", msg["From"]["Mailbox"])
    assert.equal("example.com", msg["From"]["Domain"])

    -- Recipients
    assert.equal("bcc2", msg["To"][1]["Mailbox"])
    assert.equal("example.com", msg["To"][1]["Domain"])
    assert.equal("bcc", msg["To"][2]["Mailbox"])
    assert.equal("example.com", msg["To"][2]["Domain"])
    assert.equal("cc2", msg["To"][3]["Mailbox"])
    assert.equal("example.com", msg["To"][3]["Domain"])
    assert.equal("cc", msg["To"][4]["Mailbox"])
    assert.equal("example.com", msg["To"][4]["Domain"])
    assert.equal("to2", msg["To"][5]["Mailbox"])
    assert.equal("example.com", msg["To"][5]["Domain"])
    assert.equal("to", msg["To"][6]["Mailbox"])
    assert.equal("example.com", msg["To"][6]["Domain"])

    -- Headers
    local headers = msg["Content"]["Headers"]
    assert.same({ "Bcc <bcc@example.com>,bcc2@example.com" }, headers["Bcc"])
    assert.same({ "Cc <cc@example.com>,cc2@example.com" }, headers["Cc"])
    assert.equal(1, #headers["Content-Type"])
    assert.matches("multipart/mixed; boundary=\"", headers["Content-Type"][1], 1, true)
    assert.equal(1, #headers["Date"])
    assert.same({ "From <from@example.com>" }, headers["From"])
    assert.same({ "1.0" }, headers["MIME-Version"])
    assert.equal(1, #headers["Message-ID"])
    assert.equal(1, #headers["Received"])
    assert.same({ "Reply <reply@example.com>" }, headers["Reply-To"])
    assert.same({ "<from@example.com>" }, headers["Return-Path"])
    assert.same({ "Subject" }, headers["Subject"])
    assert.same({ "To <to@example.com>,to2@example.com" }, headers["To"])
    assert.same({ "baz" }, headers["X-Bar"])
    assert.same({ "bar" }, headers["X-Foo"])

    -- MIME content
    local part = msg["MIME"]["Parts"][1]
    assert.equal("This is a multi-part message in MIME format.", part["Body"])
    assert.same({}, part["Headers"])
    assert.equal(cjson.null, part["MIME"])

    part = msg["MIME"]["Parts"][2]
    assert.same({ "Content-Type" }, tablex.keys(part["Headers"]):sort())
    assert.equal(1, #part["Headers"]["Content-Type"])
    assert.matches("multipart/alternative; boundary=\"", part["Headers"]["Content-Type"][1], 1, true)
    assert.equal("table", type(part["MIME"]))

    part = msg["MIME"]["Parts"][2]["MIME"]["Parts"][1]
    assert.same({ "Content-Transfer-Encoding", "Content-Type" }, tablex.keys(part["Headers"]):sort())
    assert.same({ "base64" }, part["Headers"]["Content-Transfer-Encoding"])
    assert.same({ "text/plain; charset=utf-8" }, part["Headers"]["Content-Type"])
    assert.equal("UGxhaW4gVGV4dA==", part["Body"])
    assert.equal(cjson.null, part["MIME"])

    part = msg["MIME"]["Parts"][2]["MIME"]["Parts"][2]
    assert.same({ "Content-Transfer-Encoding", "Content-Type" }, tablex.keys(part["Headers"]):sort())
    assert.same({ "base64" }, part["Headers"]["Content-Transfer-Encoding"])
    assert.same({ "text/html; charset=utf-8" }, part["Headers"]["Content-Type"])
    assert.equal("PHA+SFRNTCBUZXh0PC9wPg==", part["Body"])
    assert.equal(cjson.null, part["MIME"])

    -- Attachments
    part = msg["MIME"]["Parts"][3]
    assert.same({ "Content-Disposition", "Content-ID", "Content-Transfer-Encoding", "Content-Type" }, tablex.keys(part["Headers"]):sort())
    assert.same({ "attachment; filename=\"=?utf-8?B?Zm9vLnR4dA==?=\"" }, part["Headers"]["Content-Disposition"])
    assert.equal(1, #part["Headers"]["Content-ID"])
    assert.same({ "base64" }, part["Headers"]["Content-Transfer-Encoding"])
    assert.same({ "text/plain" }, part["Headers"]["Content-Type"])
    assert.equal("SGVsbG8sIFdvcmxkLg==", part["Body"])
    assert.equal(cjson.null, part["MIME"])

    part = msg["MIME"]["Parts"][4]
    assert.same({ "Content-Disposition", "Content-ID", "Content-Transfer-Encoding", "Content-Type" }, tablex.keys(part["Headers"]):sort())
    assert.same({ "inline; filename=\"=?utf-8?B?Zm9vLnR4dA==?=\"" }, part["Headers"]["Content-Disposition"])
    assert.same({ "<custom_content_id>" }, part["Headers"]["Content-ID"])
    assert.same({ "base64" }, part["Headers"]["Content-Transfer-Encoding"])
    assert.same({ "text/plain" }, part["Headers"]["Content-Type"])
    assert.equal("SGVsbG8sIFdvcmxkLg==", part["Body"])
    assert.equal(cjson.null, part["MIME"])
  end)
end)
