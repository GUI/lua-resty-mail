FROM openresty/openresty:jessie

# Locale data.
RUN apt-get install -y locales locales-all

# Install luacheck
RUN luarocks install luacheck 0.20.0-1 && \
  ln -s /usr/local/openresty/luajit/bin/luacheck /usr/local/bin/luacheck

# Install busted
RUN luarocks install busted 2.0.rc12-1 && \
  ln -s /usr/local/openresty/luajit/bin/busted /usr/local/bin/busted

# Install MailHog
RUN curl -L -o /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64 && \
  chmod +x /usr/local/bin/mailhog

# Install wait-for-it
RUN curl -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
  chmod +x /usr/local/bin/wait-for-it

RUN mkdir /app
WORKDIR /app
COPY . /app

ENTRYPOINT []
