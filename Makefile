.PHONY: all lint test test-integration-external install-test-deps-yum install-test-deps release

all:

lint:
	luacheck .

test: lint
	luarocks make --local lua-resty-mail-git-1.rockspec
	mkdir -p spec/tmp
	mailhog > spec/tmp/mailhog.log 2>&1 & echo $$! > spec/tmp/mailhog.pid
	wait-for-it localhost:1025
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" TZ="America/Denver" busted --shuffle --lua=resty --exclude-tags=integration_external spec
	kill `cat spec/tmp/mailhog.pid` && rm spec/tmp/mailhog.pid

test-integration-external:
	luarocks make --local lua-resty-mail-git-1.rockspec
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" busted --shuffle --lua=resty --tags=integration_external spec

install-test-deps-yum:
	yum -y install gcc
	sed -i '/override_install_langs/d' /etc/yum.conf
	yum -y reinstall glibc-common || yum -y install glibc-common

install-test-deps:
	luarocks install busted 2.0.rc13-0
	luarocks install luacheck 0.22.1-1
	luarocks install lua-resty-http 0.12-0
	curl -fsSL -o /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64
	chmod +x /usr/local/bin/mailhog
	curl -fsSL -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/54d1f0bfeb6557adf8a3204455389d0901652242/wait-for-it.sh
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
