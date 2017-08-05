.PHONY: lint test

lint:
	luacheck lib spec

test: lint
	luarocks make --local lua-resty-mail-git-1.rockspec
	mkdir -p spec/tmp
	mailhog > spec/tmp/mailhog.log 2>&1 & echo $$! > spec/tmp/mailhog.pid
	wait-for-it localhost:1025
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" TZ="America/Denver" busted --shuffle --lua=resty --exclude-tags=integration_external spec
	kill `cat spec/tmp/mailhog.pid` && rm spec/tmp/mailhog.pid

test_integration_external:
	luarocks make --local lua-resty-mail-git-1.rockspec
	env LUA_PATH="${HOME}/.luarocks/share/lua/5.1/?.lua;;" busted --shuffle --lua=resty --tags=integration_external spec

release:
	# Ensure the version number has been updated.
	grep -q -F 'VERSION = "${VERSION}"' lib/resty/mail.lua
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
