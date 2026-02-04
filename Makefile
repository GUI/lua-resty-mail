.PHONY: all lint test test-integration-external test-integration-ssl-certs install-test-deps release

all:

lint:
	luacheck .

test:
	luarocks make --tree "${HOME}/.luarocks" lua-resty-mail-git-1.rockspec
	mkdir -p spec/tmp
	mailpit > spec/tmp/mailpit.log 2>&1 & echo $$! > spec/tmp/mailpit.pid
	wait-for-it localhost:1025
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" TZ="America/Denver" busted --shuffle --lua=resty --exclude-tags=integration_external,integration_ssl_certs spec
	kill `cat spec/tmp/mailpit.pid` && rm spec/tmp/mailpit.pid

test-integration-external:
	luarocks make --tree "${HOME}/.luarocks" lua-resty-mail-git-1.rockspec
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" busted --shuffle --lua=resty --tags=integration_external spec

test-integration-ssl-certs:
	luarocks make --tree "${HOME}/.luarocks" lua-resty-mail-git-1.rockspec
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" busted --shuffle --lua=./spec/bin/resty-with-ssl-certs --tags=integration_ssl_certs spec

install-test-deps:
	luarocks install busted 2.3.0-1
	luarocks install luacheck 1.2.0-1
	luarocks install lua-resty-http 0.17.2-0
	arch="amd64"; \
	if [ "$$(uname -m)" = "aarch64" ]; then \
		arch="arm64"; \
	fi; \
	curl -fsSL "https://github.com/axllent/mailpit/releases/download/v1.29.0/mailpit-linux-$$arch.tar.gz" | tar -xvz -C /usr/local/bin/ --wildcards "mailpit"
	curl -fsSL -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/81b1373f17855a4dc21156cfe1694c31d7d1792e/wait-for-it.sh
	chmod +x /usr/local/bin/wait-for-it

release:
	# Ensure the version number has been updated.
	grep -q -F 'VERSION = "${VERSION}"' lib/resty/mail.lua
	# Ensure the OPM version number has been updated.
	grep -q -F 'version = ${VERSION}' dist.ini
	# Ensure the rockspec has been renamed and updated.
	grep -q -F 'version = "${VERSION}-1"' "lua-resty-mail-${VERSION}-1.rockspec"
	grep -q -F 'tag = "v${VERSION}"' "lua-resty-mail-${VERSION}-1.rockspec"
	# Ensure the CHANGELOG has been updated.
	grep -q -F '## ${VERSION} -' CHANGELOG.md
	# Check for remote tag.
	git ls-remote -t | grep -F "refs/tags/v${VERSION}^{}"
	# Verify LuaRock and OPM can be built locally.
	docker-compose run --rm -v "${PWD}:/app" app luarocks pack "lua-resty-mail-${VERSION}-1.rockspec"
	docker-compose run --rm -v "${HOME}/.opmrc:/root/.opmrc" -v "${PWD}:/app" app opm build
	# Upload to LuaRocks and OPM.
	docker-compose run --rm -v "${HOME}/.luarocks/upload_config.lua:/root/.luarocks/upload_config.lua" -v "${PWD}:/app" app luarocks upload "lua-resty-mail-${VERSION}-1.rockspec"
	docker-compose run --rm -v "${HOME}/.opmrc:/root/.opmrc" -v "${PWD}:/app" app opm upload
