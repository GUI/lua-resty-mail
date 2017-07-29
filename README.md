# lua-resty-mail

A high-level, easy to use, and non-blocking email and SMTP library for OpenResty.

## Features

Currently in progress, but expected features in first release:

- SMTP authentication, SSL, and STARTLS support.
- Multipart plain text and HTML message bodies.
- From, To, Cc, Bcc, Reply-To, and Subject fields (custom headers also supported).
- Email addresses in "test@example.com" and "Name <test@example.com>" formats.
- File attachments.

## Usage

```lua
local mail = require "resty.mail"

local mailer = mail.new({
  host = "smtp.gmail.com"
})

local ok, err = mailer.send({
  from = "Master Splinter <splinter@example.com>",
  to = { "michelangelo@example.com" },
  cc = { "leo@example.com", "Raphael <raph@example.com>", "donatello@example.com" },
  subject = "Pizza is here!",
  text = "There's pizza in the sewer.",
  html = "<h1>There's pizza in the sewer.</h1>",
})
```
