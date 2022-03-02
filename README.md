# tableToString

A basic Lua table serializer.

Many bits and pieces are taken from [Serpent](https://github.com/pkulchenko/serpent).


## Description

This module orders table contents into four groups:

1. High-priority non-tables (Optional)
2. Normal-priority non-tables, in ascending order
3. High-priority tables (Optional)
4. Normal-priority tables, in ascending order

It can serialize numbers, booleans, strings and tables-within-tables. Not supported are functions, userdata, threads (coroutines) and LuaJIT cdata.

Some exceptions apply:

* Cyclic table references (tables appearing inside of themselves) are not allowed. Tables can be values, but not keys.

* Attached metatables are not saved, and serialization may be affected by metamethods.


## Configuration

### Module-wide

* `tableToString.indent_str`: The symbol to use when indenting. *Default: space (" ")*

* `tableToString.indent_reps`: How many repetitions of the indent symbol to write at a time. *Default: 2*


### Per-Table

Format tables may be attached to tables and sub-tables to control some aspects of the serialization process.

* `fmt.priority_keys`: Sequence of strings representing fields which should be written first, in this order. *Default: Empty table*

* `fmt.missing_pri_key`: How to handle a missing priority key.
  * `"error"`: Raise a Lua error.
  * `"warn"`: Print a warning to the console.
  * `nil`: Ignore. *(Default)*

* `fmt.array_columns`: How many values in a numeric sequence to write per line. *Default: 20*


## Public Functions

`tableToString.convert(tbl, [fmt_key])`

Returns a serialized string version of `tbl`. If format tables were applied, then pass in the identifier as the second argument.


`tableToString.setFormatTable(tbl, fmt, fmt_key, [recursive])`

Assigns the table `fmt` to `tbl` using the key `fmt_key` (ie `tbl[fmt_key] = fmt`.) `fmt_key` should be something that normally doesn't appear within the table, and it can be a type that is unsupported by the serializer, such as a throwaway / dummy function.

If `recursive` is true, then the same operation is applied to all sub-tables. (NOTE: in this case, the same table reference is assigned to every sub-table. Changing the format table will affect all tables that it is attached to.)


`tableToString.scrubFormatTable(tbl, fmt_key, recursive)`

Removes the format table from `tbl` stored in `tbl[fmt_key]`. If `recursive` is true, then the same operation is applied to all sub-tables.


## Issues and Other Limitations

tableToString can serialize tables that are too deeply-nested for Lua to read back in with `require` or `loadstring`. When this happens, you will get an error message along the lines of `chunk has too many syntax levels` or `C stack overflow`.


## Supported Versions

Tested with LuaJIT 2.1.0-beta3, Lua 5.4.4, and within LÖVE 11.4 (ebe628e) with LuaJIT.


## License (MIT)

Copyright 2022 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
