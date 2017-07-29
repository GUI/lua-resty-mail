local ngx_socket_tcp = ngx.socket.tcp

local CRLF = "\r\n"

local _M = {}

local function send(sock, data)
  local bytes, send_err = sock:send(data)
  if not bytes then
    return false, send_err
  end

  local line, receive_err = sock:receive()
  if not line then
    return false, receive_err
  end

  return true
end

local function send_line(sock, line)
  -- Prevent SMTP injections, by ensuring recipients addresses don't contain
  -- line breaks or are so long that they could potentially cause line breaks.
  --
  -- See http://www.mbsd.jp/Whitepaper/smtpi.pdf
  if #line > 2000 then
    return false, "may not exceed 2kB"
  end
  if ngx.re.match(line, "[\r\n]", "jo") then
    return false, "may not contain CR or LF line breaks"
  end

  return send(sock, { line, CRLF })
end

function _M.send(mailer, message)
  local sock, ok, err

  sock, err = ngx_socket_tcp()
  if not sock then
    return false, err
  end

  sock:connect(mailer.options["host"], mailer.options["port"])
  ok, err = send_line(sock, "EHLO " .. mailer.options["host"])
  if not ok then
    return false, err
  end

  local from = message:get_from_address()
  ok, err = send_line(sock, "MAIL FROM:<" .. from .. ">")
  if not ok then
    return false, err
  end

  local recipients = message:get_recipient_addresses()
  for _, address in ipairs(recipients) do
    ok, err = send_line(sock, "RCPT TO:<" .. address .. ">")
    if not ok then
      return false, err
    end
  end

  ok, err = send_line(sock, "DATA")
  if not ok then
    return false, err
  end

  ok, err = send(sock, message:get_body_list())
  if not ok then
    return false, err
  end

  ok, err = send(sock, { CRLF, ".", CRLF })
  if not ok then
    return false, err
  end

  ok, err = send_line(sock, "QUIT")
  if not ok then
    return false, err
  end

  return true
end

return _M
