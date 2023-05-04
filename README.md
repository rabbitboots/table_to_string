**Version:** 1.0.1

# tableToString

A basic Lua table serializer.

Many bits and pieces are taken from [Serpent](https://github.com/pkulchenko/serpent).


# Description

This module orders table contents into four groups:

1. High-priority non-tables (Optional)
2. Normal-priority non-tables, in ascending order
3. High-priority tables (Optional)
4. Normal-priority tables, in ascending order

It can serialize numbers, booleans, strings and tables-within-tables. Not supported are functions, userdata, threads (coroutines) and LuaJIT cdata.

Some exceptions apply:

* Cyclic table references (tables appearing inside of themselves) are not allowed. Tables can be values, but not keys.

* Attached metatables are not saved, and serialization may be affected by metamethods.


# Configuration

## Module-wide

* `tableToString.indent_str`: The symbol to use when indenting. *Default: space (" ")*

* `tableToString.indent_reps`: How many repetitions of the indent symbol to write at a time. *Default: 2*


## Per-Table

Format tables may be attached to tables and sub-tables to control some aspects of the serialization process. The key used is stored in `tableToString.fmt_key`, and it defaults to a type that tableToString cannot serialize. While serializing, if the format key isn't found, a default table is used (stored in `tableToString.fmt_def`.)

* `fmt.priority_keys`: Sequence of strings representing fields which should be written first, in this order. *Default: `nil`*

* `fmt.missing_pri_key`: How to handle a missing priority key.
  * `"error"`: Raise a Lua error.
  * `"warn"`: Print a warning to the console.
  * `nil`: Ignore. *(Default)*

* `fmt.array_columns`: How many values in a numeric sequence to write per line. Can be false/nil for no limit, or >= 1. *Default: 20*

NOTE: Format tables do not automatically fall back to the default `tableToString.fmt_def`. If desired, this can be accomplished with the `__index` metamethod.


# Public Functions


## tableToString.convert

Converts an input table to serialized string form.

`local str = tableToString.convert(tbl)`

* `tbl`: The table to serialize.

**Returns:** The serialized string, which can be loaded as a Lua chunk.


## tableToString.setFormatTable

Assigns a format table to another table using the key `tableToString.fmt_key`.

`tableToString.setFormatTable(tbl, fmt, [recursive])`

* `tbl`: The target table to modify.
* `fmt`: The format table to attach to `tbl`.
* `recursive`: *(false)* Apply the same format table to all sub-tables.


### Notes

* This function is essentially `tbl[tableToString.fmt_key] = fmt`.

* When using `recursive`, the same `fmt` table reference is assigned to every sub-table. Changing the format table will affect *all* tables that it is attached to.


## tableToString.scrubFormatTable

Removes the format table attached to a given table.

`tableToString.scrubFormatTable(tbl, [recursive])`

* `tbl`: The table to scrub.

* `recursive`: *(false)* Remove format tables from all sub-tables as well.


# Issues and Limitations

tableToString can serialize tables that are too deeply-nested for Lua to read back in with `require` or `loadstring`. When this happens, you will get an error message along the lines of `chunk has too many syntax levels` or `C stack overflow`.

Mutating the tables to assign formatting keys is maybe not the best design. To prevent changing the tables themselves, you can use metatables and the `__index` metamethod to make the key readable without disturbing the table contents. You can also change `tableToString.fmt_key` to anything other than NaN, if the function data type is a problem.


# Supported Versions

Tested with LuaJIT 2.1.0-beta3, Lua 5.1.5, Lua 5.4.4, and within LÖVE 11.4 (ebe628e) with LuaJIT.


# License (MIT)

Copyright 2022, 2023 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
