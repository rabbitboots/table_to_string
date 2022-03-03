--[[
	tableToString tests. (For the actual library, see: table_to_string.lua)
--]]
--[[
	Copyright 2022 RBTS

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local tableToString = require("table_to_string")

local errTest = require("test.err_test")
local inspect = require("test.inspect.inspect")

--[[
Won't Fix:

* There's a limit in Lua on how deeply-nested tables can be in a table constructor. Because tableToString serializes tables as constructors, it can write out tables that are too deeply-nested to read back in with require() or load().

--]]


-- [=[
local tbl

print("Test: empty table")
tbl = {}
print(tableToString.convert(tbl))

print("Test: Values: strings, numbers (inf, NaN), booleans, tables")
tbl = {
	str = "string",
	int = 100,
	negative_int = -99,
	decimal = 0.1,
	decimal2 = 0.0000000000001,
	bool_true = true,
	bool_false = false,
	hex = 0xff,
	tbl = {},
	inf = (1/0),
	nan = (0/0),
}
print(tableToString.convert(tbl))


print("Test: Keys: strings, numbers (inf), booleans")
tbl = {
	str = "string",
	[-44] = "number",
	[(1/0)] = "inf",
	[true] = true,
	[false] = false,
}
print(tableToString.convert(tbl))


print("Test: Nested tables")
tbl = {
	{
		{
			{
				{
					{
						"Good morning",
						{
							"Hello"
						},
						"Good night",
					}
				}
			}
		}
	},
	"Goodbye",
}
print(tableToString.convert(tbl))

print("Test: Sequence, default columns")
tbl = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, }
print(tableToString.convert(tbl))

print("Test: Sequence, 8 columns")
tbl = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, }
local fmt = {array_columns = 8}
tableToString.setFormatTable(tbl, fmt, fmt)
print(tableToString.convert(tbl, fmt))


--print("Test: Priority Keys") -- see example_2.lua

--]=]

print("\n * Begin Error Testing * \n")

-- [[
do
	print("\nTesting: tableToString.convert()")
	errTest.register(tableToString.convert, "tableToString.convert")

	print("\n[-] Arg #1 bad type")
	errTest.expectFail(tableToString.convert, nil)

	print("\n[-] Arg #2 cannot be NaN")
	errTest.expectFail(tableToString.convert, {}, 0/0)

	print("\n[-] Arg #1 Cycle in table structure")
	local temp = {}
	temp.temp = {}
	temp.temp.temp = temp
	errTest.expectFail(tableToString.convert, temp)

	print("\n[-] Error upon reading unsupported type")
	local function temp_func() return; end
	local co = coroutine.create(temp_func)

	errTest.expectFail(tableToString.convert, {temp_func})
	errTest.expectFail(tableToString.convert, {co})
end
--]]

-- [[
do
	print("\nTesting: tableToString.setFormatTable()")
	errTest.register(tableToString.setFormatTable, "tableToString.setFormatTable")

	print("\n[+] Expected behavior, flat empty table")
	local t1 = {a = true, b = false}
	local f1 = {
		missing_pri_key = "warn",
		priority_keys = {
			"foo",
			"bar",
		},
	}

	local _, temp

	errTest.expectPass(tableToString.setFormatTable, t1, f1, "_~FMT~_", false)

	print("\n[+] Expected behavior, apply format key recursively to nested tables")
	local t2 = {{{{{{{{}}}}}}}}
	_, temp = errTest.expectPass(tableToString.setFormatTable, t2, f1, "_~FMT~_", true)

	print("\n[-] Arg #1 bad type")
	errTest.expectFail(tableToString.setFormatTable, false, f1, "_~FMT~_", true)

	print("\n[-] Arg #2 bad type")
	errTest.expectFail(tableToString.setFormatTable, t2, false, "_~FMT~_", true)

	print("\n[-] Arg #3 nil and NaN are not allowed")
	errTest.expectFail(tableToString.setFormatTable, t2, f1, nil, true)
	errTest.expectFail(tableToString.setFormatTable, t2, f1, (0/0), true)

	print("\n[-] Arg #4 may be nil, false or true. Try a different bad type")
	errTest.expectFail(tableToString.setFormatTable, t2, f1, "_~FMT~_", "bad_type")

	print("\n[-] Test missing pri key error")
	t1 = {a = true, b = false}
	f1 = {
		missing_pri_key = "error",
		priority_keys = {
			"foo",
			"bar",
		},
	}
	tableToString.setFormatTable(t1, f1, "_~FMT~_")
	errTest.expectFail(tableToString.convert, t1, "_~FMT~_")

	print("\n[-] Format key 'array_columns' must be nil or a number >= 1")
	t1 = {1, 2, 3, 4, 5, 6, 7, 8,}
	f1 = {array_columns = false}
	tableToString.setFormatTable(t1, f1, "_~FMT~_")
	errTest.expectFail(tableToString.convert, t1, "_~FMT~_")
	
	print("\n[-] Format key 'missing_pri_key' must be nil or a string.")
	t1 = {1, 2, 3, 4, 5, 6, 7, 8,}
	f1 = {missing_pri_key = false}
	tableToString.setFormatTable(t1, f1, "_~FMT~_")
	errTest.expectFail(tableToString.convert, t1, "_~FMT~_")

	print("\n[-] Format key 'priority_keys' must be nil or a table. (Verifying that they are sequences is a bit much IMO.)")
	t1 = {1, 2, 3, 4, 5, 6, 7, 8,}
	f1 = {priority_keys = false}
	tableToString.setFormatTable(t1, f1, "_~FMT~_")
	errTest.expectFail(tableToString.convert, t1, "_~FMT~_")
end
--]]


-- [[
do
	print("\nTesting: tableToString.scrubFormatTable()")
	errTest.register(tableToString.scrubFormatTable, "tableToString.scrubFormatTable")

	print("\n[+] Expected behavior, flat table")
	local t1 = {}
	local f1 = {
		missing_pri_key = "warn",
		priority_keys = {
			"foo",
			"bar",
		},
	}

	tableToString.setFormatTable(t1, f1, "_~FMT~_", false)
	errTest.expectPass(tableToString.scrubFormatTable, t1, "_~FMT~_", false)

	local _, temp

	print("\n[+] Expected behavior, scrub format key recursively from nested tables")
	local t2 = {{{{{{{{}}}}}}}}
	tableToString.setFormatTable(t2, f1, "_~FMT~_", true)
	
	errTest.expectPass(tableToString.scrubFormatTable, t2, "_~FMT~_", true)

	print("\n[-] Arg #1 bad type")
	errTest.expectFail(tableToString.scrubFormatTable, false, "_~FMT~_", true)
	
	print("\n[-] Arg #2 nil and NaN are not allowed")
	errTest.expectFail(tableToString.scrubFormatTable, t2, nil, true)
	errTest.expectFail(tableToString.scrubFormatTable, t2, (0/0), true)
	
	print("\n[-] Arg #3 may be nil, false or true. Try a different bad type")
	errTest.expectFail(tableToString.scrubFormatTable, t2, "_~FMT~_", "bad_type")
end
--]]

print("\n * End Error Testing * \n")


print("\n * Start Med-Sized Table Test * \n")
do
	local inc_nan = true
	local inc_inf = true
	
	local root = {}
	local tbl = root
	local actions = {"i", "nt", "s", "i", "i", "i", "s", "i", "nt", "i", "i", "s", "nt", "s", "bt", "bt", "i", "bt", "bf", "bf"}

	if inc_nan then
		for i = 1, 4 do
			table.insert(actions, "nan")
		end
	end
	if inc_inf then
		for i = 1, 4 do
			table.insert(actions, "inf")
		end
	end
	
	local i = 1
	local tumbler = 1
	local max = 256
	for i = 1, max do
		local action = actions[(tumbler - 1) % (#actions) + 1]
		tumbler = tumbler + i

		-- New table
		if action == "nt" then
			tbl[i] = {}
			tbl = tbl[i]

		-- Number
		elseif action == "i" then
			tbl[i] = i

		-- String
		elseif action == "s" then
			tbl[i] = tostring(i)

		-- inf
		elseif action == "inf" then
			tbl[i] = (1/0)

		-- NaN
		elseif action == "nan" then
			tbl[i] = (0/0)

		-- Bool true
		elseif action == "bt" then
			tbl[i] = true

		-- Bool false
		elseif action == "bf" then
			tbl[i] = false
		end
	end

	local tbl_str = tableToString.convert(root)
	print("String ver:\n")
	print(tbl_str)
	local str_fn = assert(load(tbl_str))
	local fn_tbl = str_fn()
	print("Inspect output:\n")
	print(inspect(fn_tbl))

	-- Compare table contents
	local function deepTableCompare(a, b, _depth)
		_depth = _depth or 1
		
		-- Check every field in A against B.
		for k in pairs(a) do
			if type(a[k]) ~= type(b[k]) then
				print(_depth, "Type mismatch: " .. type(a[k]) .. ", " .. type(b[k]))
				return false

			elseif type(a[k]) == "table" then
				if deepTableCompare(a[k], b[k], _depth + 1) == false then
					print(_depth, "Table mismatch: " .. tostring(a[k]) .. ", " .. tostring(b[k]))
					return false
				end

			-- Catch nan == nan
			elseif a[k] ~= a[k] and b[k] ~= b[k] then
				-- (Do nothing)

			elseif a[k] ~= b[k] then
				print(_depth, "Value mismatch: " .. tostring(a[k]) .. ", " .. tostring(b[k]))
				return false
			end
		end
		-- Check B for fields that don't exist in A.
		for k in pairs(b) do
			if a[k] == nil then
				print(_depth, "Value in B (" .. tostring(k) .. ":" .. tostring(a[k]) .. ") not in A.")
				return false
			end
		end

		return true
	end
	
	print("deepTableCompare: ", deepTableCompare(root, fn_tbl))
end

print("\n * End Med-Sized Table Test * \n")

print("\n * Script complete * \n")

if love then
	love.event.quit()
end