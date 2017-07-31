package = "lua-resty-mail"
version = "git-1"
source = {
  url = "git://github.com/GUI/lua-resty-mail.git",
}
description = {
  summary = "libcidr bindings for Lua",
  detailed = "Perform various CIDR and IP address operations to check IPv4 and IPv6 ranges.",
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
