// console.log("Hello via Bun!");

import { $ } from 'bun';

const out = await $`./luarocks/bin/busted.bat --helper=./tests/testhelper.lua ./tests`.text();
console.log(out)
