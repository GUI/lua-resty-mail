package = "lua-resty-mail"
version = "1.0.2-1"
source = {
  url = "git://github.com/GUI/lua-resty-mail.git",
  tag = "v1.0.2",
}
description = {
  summary = "Email and SMTP library for OpenResty",
  detailed = "A high-level, easy to use, and non-blocking email and SMTP library for OpenResty.",
  homepage = "https://github.com/GUI/lua-resty-mail",
  license = "MIT",
}
build = {
  type = "builtin",
  modules = {
    ["resty.mail"] = "lib/resty/mail.lua",
    ["resty.mail.message"] = "lib/resty/mail/message.lua",
    ["resty.mail.smtp"] = "lib/resty/mail/smtp.lua",
    ["resty.mail.headers"] = "lib/resty/mail/headers.lua",
    ["resty.mail.rfc2822_date"] = "lib/resty/mail/rfc2822_date.lua",
  },
}
