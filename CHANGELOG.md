# lua-resty-mail Change Log

## 1.1.0 - 2023-09-23

### Added
- Add a `ssl_verify` option to turn on SSL certificate verification (defaults to `false`).
- Add a `ssl_host` option to override the hostname used for SNI and TLS verification (instead of the default `host`).

### Fixed
- Fixed potential bug if using the `ssl = true` option that could cause the connection to close early if the server also supported STARTLS.

### Changed
- Upgraded test dependencies and moved CI testing to GitHub Actions.

## 1.0.2 - 2019-02-24

### Fixed
- Fix sending authentication credentials when using the `login` option for `auth_type`.

## 1.0.1 - 2018-11-26

### Fixed
- Fix compatibility with older versions of ngx_lua (pre v0.10.7) that lack `tcpsock:settimeouts` support.

## 1.0.0 - 2017-08-05

- Initial release.
