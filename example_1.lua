-- tableToString: An example without format tables.


require("test_lib.strict")


local inspect = require("test_lib.inspect.inspect")


local _load = (_VERSION == "Lua 5.1") and loadstring or load


local tableToString = require("table_to_string")

-- The table to serialize.
local tbl = {
  [1] = true,
  [false] = "&",
  str = {
    [(1/0)] = (0/0), -- key is inf, value is NaN
    foo = {
      "bar",
      seq = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25}
    }
  }
}

local str = tableToString.convert(tbl)
print(str)

--[[
-- Output:

return {
  [false] = "&",
  [1] = true,
  str = {
    [1/0] = 0/0,
    foo = {
      [1] = "bar",
      seq = {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 
        21, 22, 23, 24, 25, 
      },
    },
  },
}

--]]

print("\nExamine the reloaded table.\n")
local str_fn = _load(str)
local fn_str = str_fn()

print(inspect(fn_str))
