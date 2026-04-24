package.path = "./?.lua;./?/init.lua;" .. package.path

require("tests/TestUtils")
require("tests/TestAcquisitionLogic")
require("tests/TestUiLogic")

local lu = require("luaunit")
os.exit(lu.LuaUnit.run())
