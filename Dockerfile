FROM debian:jessie

# Install OpenResty
RUN \
  apt-get update && \
  apt-get -y install curl software-properties-common && \
  curl https://openresty.org/package/pubkey.gpg | apt-key add -  &&\
  add-apt-repository -y "deb http://openresty.org/package/debian $(lsb_release -sc) openresty" && \
  apt-get update && \
  apt-get -y install openresty

# Install LuaRocks
RUN apt-get -y install git make unzip gcc && \
  curl -OL http://luarocks.github.io/luarocks/releases/luarocks-2.4.2.tar.gz && \
  tar -xvf luarocks-2.4.2.tar.gz && \
  cd luarocks-2.4.2 && \
  ./configure --prefix=/usr/local/openresty/luajit \
    --with-lua=/usr/local/openresty/luajit \
    --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    --lua-suffix=jit && \
  make build && \
  make install && \
  ln -s /usr/local/openresty/luajit/bin/luarocks /usr/local/bin/luarocks

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
