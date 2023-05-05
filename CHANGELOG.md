# TableToString Changelog

(Date format: `YYYY-MM-DD`)

# 1.0.2 (2023-05-05)

* `table_to_string.lua`: Make the radix mark locale fix more robust (it would break if the user changed locales *after* loading the module). This might still break if the locale changes while `tableToString.convert()` is running, though I wasn't able to make it happen with a threaded test project in LÖVE / Linux.
* Minor whitespace adjustments in examples.


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

