local mail_headers = require "resty.mail.headers"
local resty_random = require "resty.random"
local str = require "resty.string"

local random_bytes = resty_random.bytes
local encode_base64 = ngx.encode_base64
local to_hex = str.to_hex
local match = ngx.re.match
local CRLF = "\r\n"

local _M = {}

local function body_insert_header(body, name, value)
  if value then
    table.insert(body, name)
    table.insert(body, ": ")
    table.insert(body, value)
    table.insert(body, CRLF)
  end
end

local function body_insert_boundary(body, boundary)
  table.insert(body, "--")
  table.insert(body, boundary)
  table.insert(body, CRLF)
end

local function body_insert_boundary_final(body, boundary)
  table.insert(body, "--")
  table.insert(body, boundary)
  table.insert(body, "--")
  table.insert(body, CRLF)
  table.insert(body, CRLF)
end

local function extract_address(string)
  local captures, err = match(string, [[<\s*(.+?@.+?)\s*>]], "jo")
  if captures then
    return captures[1]
  else
    if err then
      ngx.log(ngx.ERR, "lua-resty-mail: regex error: ", err)
    end

    return string
  end
end

local function random_tag()
  local num_bytes = 32
  local random = random_bytes(num_bytes, true)
  if not random then
    random = random_bytes(num_bytes, false)
  end

  return math.floor(ngx.now()) .. "." .. to_hex(random)
end

local function generate_boundary()
  return "--==_mimepart_" .. random_tag()
end

local function generate_message_id(data)
  local host
  if data and data["from"] then
    local captures, err = match(data["from"], "@(.+)", "jo")
    if captures then
      host = captures[1] .. ".mail"
    elseif err then
      ngx.log(ngx.ERR, "lua-resty-mail: regex error: ", err)
    end
  end

  if not host then
    host = "localhost.localdomain"
  end

  return "<" .. random_tag() .. "@" .. host .. ">"
end

function _M.new(data)
  if not data then
    data = {}
  end

  local headers = mail_headers.new()
  if data["headers"] then
    for name, value in ipairs(data["headers"]) do
      headers[name] = value
    end
  end

  if data["from"] then
    headers["From"] = data["from"]
  end

  if data["reply_to"] then
    headers["Reply-To"] = data["reply_to"]
  end

  if data["to"] then
    headers["To"] = table.concat(data["to"], ",")
  end

  if data["cc"] then
    headers["Cc"] = table.concat(data["cc"], ",")
  end

  if data["bcc"] then
    headers["Bcc"] = table.concat(data["bcc"], ",")
  end

  if data["subject"] then
    headers["Subject"] = data["subject"]
  end

  if not headers["Message-ID"] then
    headers["Message-ID"] = generate_message_id(data)
  end

  if not headers["MIME-Version"] then
    headers["MIME-Version"] = "1.0"
  end

  data["headers"] = headers

  return setmetatable({ data = data }, { __index = _M })
end

function _M.get_from_address(self)
  local from
  if self.data["from"] then
    from = extract_address(self.data["from"])
  end

  return from
end

function _M.get_recipient_addresses(self)
  local fields = { "to", "cc", "bcc" }
  local uniq_addresses = {}
  for _, field in ipairs(fields) do
    if self.data[field] then
      for _, string in ipairs(self.data[field]) do
        uniq_addresses[extract_address(string)] = 1
      end
    end
  end

  local list = {}
  for address, _ in pairs(uniq_addresses) do
    table.insert(list, address)
  end

  table.sort(list)

  return list
end

function _M.get_body_list(self)
  local data = self.data
  local headers = data["headers"]
  local body = {}

  local mixed_boundary
  if data["text"] or data["html"] or data["attachments"] then
    mixed_boundary = generate_boundary()
    headers["Content-Type"] = 'multipart/mixed; charset=utf-8; boundary="' .. mixed_boundary .. '"'
  end

  for name, value in pairs(headers) do
    body_insert_header(body, name, value)
  end

  table.insert(body, CRLF)

  if data["text"] or data["html"] or data["attachments"] then
    body_insert_boundary(body, mixed_boundary)

    local alternative_boundary = generate_boundary()
    body_insert_header(body, "Content-Type", 'multipart/alternative; charset=utf-8; boundary="' .. alternative_boundary .. '"')
    table.insert(body, CRLF)

    if data["text"] then
      body_insert_boundary(body, alternative_boundary)
      body_insert_header(body, "Content-Type", "text/plain; charset=utf-8")
      body_insert_header(body, "Content-Transfer-Encoding", "base64")
      table.insert(body, CRLF)
      table.insert(body, encode_base64(data["text"]))
      table.insert(body, CRLF)
    end

    if data["html"] then
      body_insert_boundary(body, alternative_boundary)
      body_insert_header(body, "Content-Type", "text/html; charset=utf-8")
      body_insert_header(body, "Content-Transfer-Encoding", "base64")
      table.insert(body, CRLF)
      table.insert(body, encode_base64(data["html"]))
      table.insert(body, CRLF)
    end

    body_insert_boundary_final(body, alternative_boundary)

    if data["attachments"] then
      body_insert_boundary(body, mixed_boundary)
    end

    body_insert_boundary_final(body, mixed_boundary)
  end

  return body
end

function _M.get_body_string(self)
  return table.concat(self:get_body_list(), "")
end

return _M
