# lua-resty-mail Change Log

## 1.0.2 - 2019-02-24

### Fixed
- Fix sending authentication credentials when using the `login` option for `auth_type`.

## 1.0.1 - 2018-11-26

### Fixed
- Fix compatibility with older versions of ngx_lua (pre v0.10.7) that lack `tcpsock:settimeouts` support.

## 1.0.0 - 2017-08-05

- Initial release.
