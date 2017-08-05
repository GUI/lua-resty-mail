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
