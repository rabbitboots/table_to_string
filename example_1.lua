--[[
	tableToString: An example without format tables.
--]]

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
local str_fn = load(str)
local fn_str = str_fn()

local function temp_print(tbl, depth) -- It's no Inspect, but you get the idea.
	if depth > 0 then
		io.write(string.rep("  ", depth))
	end

	for k, v in pairs(tbl) do
		if type(v) == "table" then
			print(tostring(k) .. " == Table:")
			temp_print(v, depth + 1)

		else
			print(tostring(k) .. " == " .. tostring(v))
		end
	end
end
temp_print(fn_str, 0)

