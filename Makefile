.PHONY: all test check native-tests ui-tests
all:
	python3 scripts/build.py
native-tests:
	mkdir -p build
	xcrun clang -fobjc-arc -Wall -Wextra -Werror -framework Foundation -framework JavaScriptCore tests/jscore.m -o build/jscore-tests
	build/jscore-tests "$(CURDIR)"
	xcrun clang -fobjc-arc -Wall -Wextra -Werror -Isrc -framework Foundation tests/runtime.m src/ZZRuntime.m -o build/runtime-tests
	build/runtime-tests
	xcrun clang -fobjc-arc -Wall -Wextra -Werror -Isrc -framework Foundation tests/configuration.m src/ZZConfigurationStore.m -o build/configuration-tests
	build/configuration-tests
test: native-tests
	node --test tests/*.test.cjs
check: all test
	python3 -m unittest discover -s tests -p 'test_*.py'

ui-tests: all
	python3 scripts/test_ui.py
