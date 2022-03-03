-- Module: tableToString
-- Description: Serializes a subset of Lua tables, with some ordering and formatting options.
-- Author: RBTS

--[[
	Many bits and pieces are taken from Serpent by Paul Kulchenko:
	https://github.com/pkulchenko/serpent
--]]

--[[
	Copyright 2022 RBTS

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local tableToString = {}

-- Module Config

-- Indentation
tableToString.indent_str = " "
tableToString.indent_reps = 2

local policyFunc = {
	["error"] = function(str) error(str, 3); end,
	["warn"] = function(str) print("Warning: " .. str); end,
}

-- / Module Config

-- Lookup Tables

local _fmt_dummy = {}

-- Accepted types for keys.
local lut_good_key_types = {
	["boolean"] = true,
	["number"] = true,
	["string"] = true,
}
-- Accepted types for values.
local lut_good_val_types = {
	["boolean"] = true,
	["number"] = true,
	["string"] = true,
	["table"] = true,
}
-- Lua reserved keywords. When used as keys, they need square bracket notation.
local lut_names_reserved = {
	["and"]			= true,
	["break"]		= true,
	["do"]			= true,
	["else"]		= true,
	["elseif"]		= true,
	["end"]			= true,
	["false"]		= true,
	["for"]			= true,
	["function"]	= true,
	["if"]			= true,
	["in"]			= true,
	["local"]		= true,
	["nil"]			= true,
	["not"]			= true,
	["or"]			= true,
	["repeat"]		= true,
	["return"]		= true,
	["then"]		= true,
	["true"]		= true,
	["until"]		= true,
	["while"]		= true,
}

-- Strings to represent special numbers.
local lut_number_strings = {
	[tostring(1/0)]		= '1/0', -- math.huge
	[tostring(-1/0)]	='-1/0', -- -math.huge
	[tostring(0/0)]		= '0/0', -- NaN
}

--[[
	Sorting priority:
		false
		true
		lower numbers
		lower strings lower-case
		lower strings upper-case
-]]
local lut_type_priority = {
	["boolean"] = 1,
	["number"] = 2,
	["string"] = 3,
}

local lut_bool_priority = {
	[false] = 1,
	[true] = 2
}

-- / Lookup Tables

-- Assertions

local function _assertArgType(arg_n, var, allowed_types)
	-- 'allowed_types' can be a single string or a table sequence of strings.
	if type(allowed_types) == "table" then
		for i, type_enum in ipairs(allowed_types) do
			if type(var) == type_enum then
				return
			end
		end
		error("bad argument #" .. arg_n .. " (Expected (" .. table.concat(allowed_types, ", ") .. "), got " .. type(var) .. ")", 2)

	elseif type(var) ~= allowed_types then
		error("bad argument #" .. arg_n .. " (Expected " .. allowed_types .. ", got " .. type(var) .. ")", 2)
	end
end
local _type_non_nil = {"boolean", "cdata", "function", "number", "string", "table", "thread", "userdata"}

local function _assertArgNotNan(arg_n, var)
	if var ~= var then
		error("Argument #" .. arg_n .. " cannot be NaN.")
	end
end

local function _assertNoCycles(tbl, _seen)
	if _seen[tbl] then
		error("Multiple appearances of table: " .. tostring(tbl))
	end
end

-- / Assertions

-- Helpers

local function indent(n)
	return string.rep(tableToString.indent_str, tableToString.indent_reps * n)
end


local function isWritableKey(str)
	-- Cannot be a reserved Lua keyword
	if lut_names_reserved[str] then
		return false

	-- Must be comprised of a-z, A-Z, 0-9, or underscore. Cannot begin with 0-9.
	elseif string.match(str, "^[%l%u_][%w_]*$") then
		return true
	end

	return false
end


local function alphabetize(tbl, sort_func)
	-- Keys are all assumed to be strings. Sort alphabetically.
	local seq_az = {}
	for k in pairs(tbl) do
		seq_az[#seq_az + 1] = k
	end

	table.sort(seq_az, sort_func)

	return seq_az
end


local function sort_upper(a, b)
	return string.upper(a) < string.upper(b)
end


local function sort_numStr(a, b)
	if type(a) == "number" and type(b) == "string" then
		return true

	elseif type(a) == "string" and type(b) == "number" then
		return false

	else
		return a < b
	end
end


local function sort_boolNumStr(a, b)
	local ta, tb = type(a), type(b)

	-- Different types: go by lookup table
	if ta ~= tb then
		return lut_type_priority[ta] < lut_type_priority[tb]

	-- Booleans: priority to false	
	elseif ta == "boolean" then
		return lut_bool_priority[a] < lut_bool_priority[b]

	-- Numbers and strings can be compared with the less-than operator.
	elseif ta == "number" or ta == "string" then
		return a < b

	-- Anything else is not supported.
	else
		error("Unsupported sort type: " .. ta)
	end
end

-- / Helpers

-- Internal Functions

local function o_indent(self)
	self:app(indent(self.indent_level))
end


local function o_append(self, str)
	self.arr[#self.arr + 1] = str
end


local function routeKey(k, v, grp_table, grp_other)
	if type(v) == "table" then
		grp_table[k] = v

	else
		grp_other[k] = v
	end
end


local function appendArray(arr1, arr2)
	local i1 = #arr1 + 1

	for i = 1, #arr2 do
		local key = i
		local value = arr2[i]

		arr1[i1] = i
		i1 = i1 + 1
		arr1[i1 + 1] = value
	end
end


local function appendArrayGuide(arr, hash, guide)
	local i1 = #arr + 1

	for i = 1, #guide do
		local key = guide[i]
		local value = hash[key]

		arr[i1] = key
		i1 = i1 + 1
		arr[i1] = value
		i1 = i1 + 1
	end
end


local function getSortedKeys(tbl, fmt_t, fmt_key)
	local priority_list
	fmt_t = fmt_t or {}
	priority_list = fmt_t.priority_keys or {}

	local key_types = "array"
	local val_other_h = {}
	local val_other = {}
	local val_table_h = {}
	local val_table = {}

	local int_highest

	-- Make a temporary, filtered copy of tbl that we can modify.
	local tbl_c = {}
	for k, v in pairs(tbl) do
		-- Ignore format key table
		if k ~= fmt_key then
			-- Allowed types?
			if not lut_good_key_types[type(k)] then
				error("Can't serialize key of type: " .. type(k))

			elseif not lut_good_val_types[type(v)] then
				error("Can't serialize value of type: " .. type(v))

			else
				tbl_c[k] = v

				-- Switch to hash formatting if encountering any non-numeric key, or any integer key less than 1.
				local k_type = type(k)
				if k_type ~= "number" or (k_type == "number" and k ~= math.floor(k) or k < 1) then
					key_types = "hash"
				end

				-- Track highest integer key for sparse array check below.
				if k_type == "number" then
					if not int_highest or k > int_highest then
						int_highest = k
					end
				end
			end
		end
	end

	-- Sparse array check
	if key_types == "array" then
		if not int_highest then
			key_types = "hash"

		else
			for i = 1, int_highest do
				if tbl[i] == nil then
					key_types = "hash"
					break
				end
			end
		end
	end

	-- If this is an array, just return the current order.
	if key_types == "array" then
		local ordered = {}
		local j = 1
		for i = 1, #tbl_c do
			ordered[j] = i
			ordered[j + 1] = tbl_c[i]
			j = j + 2
		end

		return ordered, key_types
	end

	-- Hash only: Place high-priority keys first
	for i, key in ipairs(priority_list) do
		if tbl_c[key] == nil then
			local policyExec = policyFunc[fmt_t.missing_pri_key]
			if policyExec then
				policyExec("Missing priority key: " .. tostring(key))
			end

		else
			routeKey(key, tbl_c[key], val_table_h, val_other_h)
		end
		tbl_c[key] = nil
	end

	-- Build guides for high-priority fields from the priority list
	local guide_other_h = {}
	local guide_table_h = {}
	for i, v in ipairs(priority_list) do
		if val_other_h[v] ~= nil then
			guide_other_h[#guide_other_h + 1] = v

		elseif val_table_h[v] ~= nil then
			guide_table_h[#guide_table_h + 1] = v
		end
	end

	-- Place the remaining keys.
	for k, v in pairs(tbl_c) do
		routeKey(k, v, val_table, val_other)
	end

	-- Sort non-priority tables
	local sorted_table = {}
	local sorted_other = {}
	local i = 1
	for k, v in pairs(val_other) do
		sorted_other[i] = k
		i = i + 1
	end
	i = 1
	for k, v in pairs(val_table) do
		sorted_table[i] = k
		i = i + 1
	end

	table.sort(sorted_other, sort_boolNumStr)
	table.sort(sorted_table, sort_boolNumStr)

	-- Collate into one array

	-- * In this order:
		-- High-priority non-tables
		-- Normal-priority non-tables, ascending order
		-- High-priority tables
		-- Normal-priority tables, ascending order

	-- * In this format:
		-- 1 key 1
		-- 2 val 1
		-- 3 key 2
		-- 4 val 2
		-- ...

	local sorted_combined = {}

	appendArrayGuide(sorted_combined, val_other_h, guide_other_h)

	appendArrayGuide(sorted_combined, val_other, sorted_other)

	appendArrayGuide(sorted_combined, val_table_h, guide_table_h)

	appendArrayGuide(sorted_combined, val_table, sorted_table)

	return sorted_combined, key_types
end


local function formatNumber(number)
	-- Attempt to keep precision of floating point values.
	local num_s = string.format("%.17g", number)

	-- Check some special cases.
	if lut_number_strings[num_s] then
		num_s = lut_number_strings[num_s]
	end

	return num_s
end


local function formatStringSafe(str)
	-- Format string for later safe reading
	str = string.format("%q", str)
	-- Escape newlines
	str = string.gsub(str, "\010","n")
	-- Escape EOF
	str = string.gsub(str, "\026","\\026")

	return str
end


local function write_hash_key(self, key)
	if type(key) == "string" then
		-- Key conforms to 'foo.bar123' syntax:
		if isWritableKey(key) then
			self:app(key)

		-- Otherwise, use foo["bar123"]:
		else
			-- Escape any sequences that could cause issues
			key = formatStringSafe(key)

			self:app("[" .. key .. "]")
		end

	elseif type(key) == "number" then
		self:app("[" .. formatNumber(key) .. "]")

	elseif type(key) == "boolean" then
		self:app("[" .. tostring(key) .. "]")

	else
		error("Unsupported key type: " .. type(key))
	end
end


function tableToString._write_value(self, value, fmt_key)
	if type(value) == "string" then
		-- Escape any sequences that could cause issues
		value = formatStringSafe(value)
		self:app(value)

	elseif type(value) == "number" then
		-- Check some numerical special cases
		local val_s = formatNumber(value)
		self:app(val_s)

	elseif type(value) == "boolean" then
		self:app(tostring(value))

	elseif type(value) == "table" then
		if self.seen[value] then
			error("Cycle in table structure: " .. tostring(value))

		else
			self.seen[value] = true
		end

		-- Empty table?
		if next(value) == nil then
			self:app("{}")

		else
			self:app("{\n")
			self.indent_level = self.indent_level + 1
			tableToString._write_table(self, value, fmt_key)

			self.indent_level = self.indent_level - 1
			self:indent()
			self:app("}")
		end
	end
end


function tableToString._write_table(self, tbl, fmt_key)
	-- Resolve format table, check type
	local fmt_t
	if fmt_key == nil then
		fmt_t = _fmt_dummy
	else
		fmt_t = tbl[fmt_key] or _fmt_dummy
	end
	if type(fmt_t) ~= "table" then
		error("'tbl[fmt_key]' must be nil or a table.")
	end

	-- Retrieve, verify array_columns
	local array_columns = (fmt_t.array_columns == nil) and 20 or fmt_t.array_columns

	if type(array_columns) ~= "number" or array_columns < 1 then
		print("fmt_t.array_columns", fmt_t.array_columns, array_columns)
		error("'array_columns' must be a number >= 1 (or nil for the default setting.)")
	end

	-- Check types of missing_pri_keys and priority_keys
	local type_check
	type_check = type(fmt_t.missing_pri_key)
	if type_check ~= "nil" and type_check ~= "string" then
		error("'missing_pri_key' must be nil or a string.")
	end
	type_check = type(fmt_t.priority_keys)
	if type_check ~= "nil" and type_check ~= "table" then
		error("'priority_keys' must be nil or a table.")
	end

	local list, key_types = getSortedKeys(tbl, fmt_t, fmt_key)

	if key_types == "array" then
		local arr_len = #list
		local count = 0

		self:indent()

		for i = 1, #list, 2 do
			local key = list[i]
			local val = list[i + 1]

			-- No key to write for arrays
			tableToString._write_value(self, val, fmt_key)

			-- Reset column count if the value just written was a table.
			if type(val) == "table" then
				count = 0
			end

			count = count + 1
			if count < arr_len then
				self:app(", ")

				if count % array_columns == 0 then
					self:app("\n")
					self:indent()
				end
			end
		end
		self:app("\n")

	elseif key_types == "hash" then
		for i = 1, #list, 2 do
			local key = list[i]
			local val = list[i + 1]

			self:indent()

			write_hash_key(self, key)
			self:app(" = ")
			tableToString._write_value(self, val, fmt_key)

			self:app(",\n")
		end
	end
end


local function newAppendObject()
	local self = {}

	self.arr = {} -- array-of-strings workspace
	self.seen = {} -- For checking cycles

	self.indent_level = 0

	-- Methods
	self.indent = o_indent -- Write indentation whitespace
	self.app = o_append -- Write a new line to self.arr

	return self
end


function _scrubFormatTable(tbl, fmt_key, recursive, _seen)

	-- Check for table cycles
	_assertNoCycles(tbl, _seen)
	_seen[tbl] = true

	tbl[fmt_key] = nil

	if recursive then
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				_scrubFormatTable(v, fmt_key, recursive, _seen)
			end
		end
	end
end


local function _setFormatTable(tbl, fmt, fmt_key, recursive, _seen)

	-- Check for table cycles
	_assertNoCycles(tbl, _seen)
	_seen[tbl] = true

	tbl[fmt_key] = fmt

	if recursive then
		for k, v in pairs(tbl) do
			-- Don't touch the format key
			if k ~= fmt_key and type(v) == "table" then
				_setFormatTable(v, fmt, fmt_key, recursive, _seen)
			end
		end
	end
end


-- / Internal Functions

-- Public Interface

--- Convert a Lua table with basic data types and no cycles to a string.
-- @param tbl The table to convert.
-- @param fmt_key (Optional) A key which identifies the format table within this and all sub-tables. Can be anything except NaN. Missing keys in the table or sub-tables are ignored.
-- @return Serialized string version of 'tbl'.
function tableToString.convert(tbl, fmt_key)

	_assertArgType(1, tbl, "table")
	_assertArgNotNan(2, fmt_key)

	local obj = newAppendObject()
	obj:app("return {\n")
	obj.indent_level = 1

	tableToString._write_table(obj, tbl, fmt_key)

	obj:app("}")

	return table.concat(obj.arr)
end


--- Assign a 'format key' to a table, and optionally all of its sub-tables. The format key allows you to customize the output on a per-table basis.
-- @param tbl The source table to configure.
-- @param fmt The format table. (Note: contents are copied to a new table.)
-- @param fmt_key A field value which is used to identify the format table. Needs to be something that does not normally appear in the table structure. Can be anything but nil or NaN.
-- @param recursive (Optional, boolean, default: false) When true, recursively apply this format table to all child tables as well.
-- @param _seen Private-use table used for detecting cycles. Leave nil when calling.
function tableToString.setFormatTable(tbl, fmt, fmt_key, recursive)

	-- Defaults
	recursive = recursive or false

	-- Check input
	_assertArgType(1, tbl, "table")
	_assertArgType(2, fmt, "table")
	_assertArgType(3, fmt_key, _type_non_nil)
	_assertArgNotNan(3, fmt_key)
	_assertArgType(4, recursive, "boolean")

	_setFormatTable(tbl, fmt, fmt_key, recursive, {})
end


--- Remove the 'format key' from a table, and optionally its subtables.
-- @param tbl The table to clean up.
-- @fmt_key The field name used to identify the format table, as set with tableToString.setFormatTable(). Can be anything but nil or NaN.
-- @param recursive (Optional, boolean, default: false) When true, recursively clean the format key from all sub-tables.
function tableToString.scrubFormatTable(tbl, fmt_key, recursive)

	-- Defaults
	recursive = recursive or false

	-- Check input
	_assertArgType(1, tbl, "table")
	_assertArgType(2, fmt_key, _type_non_nil)
	_assertArgNotNan(2, fmt_key)
	_assertArgType(3, recursive, "boolean")

	_scrubFormatTable(tbl, fmt_key, recursive, {})
end

-- / Public Interface

return tableToString

