all: test

test:
	busted ./tests --helper=./tests/testhelper.lua

