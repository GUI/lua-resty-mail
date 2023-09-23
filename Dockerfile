FROM openresty/openresty:1.21.4.2-rocky

# Test dependencies.
RUN yum -y install \
  gcc \
  glibc-langpack-fr \
  make

# Dependencies for the release process.
RUN yum -y install git zip

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt

RUN mkdir /app
WORKDIR /app

COPY Makefile /app/Makefile
RUN make install-test-deps

COPY . /app
