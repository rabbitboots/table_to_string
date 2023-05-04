-- tableToString: Test radix mark fix.


require("test_lib.strict")


assert(os.setlocale('fr_FR'))


local tableToString = require("table_to_string")


local tbl = {0.5}

print("Expected: 0.5 (not 0,5)\n")

print(tableToString.convert(tbl))

