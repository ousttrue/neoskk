all: test

test:
	busted --helper=./tests/testhelper.lua ./tests

