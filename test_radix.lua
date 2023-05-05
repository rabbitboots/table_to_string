-- tableToString: Test radix mark fix.


require("test_lib.strict")


local tableToString = require("table_to_string")


assert(os.setlocale('fr_FR'))


local tbl = {0.5}

print("Expected: 0.5 (not 0,5)\n")

print(tableToString.convert(tbl))

