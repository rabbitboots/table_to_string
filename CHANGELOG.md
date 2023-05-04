# TableToString Changelog

(Date format: `YYYY-MM-DD`)

# 1.0.1 (2023-05-04)

* `table_to_string.lua`:
  * Converted \_VERSION, \_DESCRIPTION and \_LICENSE from Lua values to comments.
  * Added locale-dependent radix mark fix for `string.format()` from Serpent (see `test_radix.lua`).
  * Formatting (whitespace).
* `main.lua`: Lua 5.1 support (select `load` or `loadstring` depending on the version).
* `example_1.lua`:
  * Lua 5.1 support (same as `main.lua`).
  * Replaced quick-and-dirty table printing loop with a call to `inspect`.
* Reformatted `README.lua`.
* Minor reformatting of examples.
* Started changelog.

