--[[
	tableToString: An example of reading format tables via the '__index'
	metamethod, to avoid disturbing table contents.
--]]


require("test_lib.strict")


local tableToString = require("table_to_string")


-- The table to serialize.
local people = {
	bimmy = {
		head = "baseball_cap",
		l_arm = "wrist_watch",
		r_arm = "nothing",
		torso = "shirt",
		legs = "shorts",
		feet = "sandals",
	},
	goober = {
		head = "goo",
		l_arm = "goo",
		r_arm = "goo",
		torso = "goo",
		legs = "goo",
		feet = "goo",
	},
	ripentear = {
		head = "tactical_helmet",
		l_arm = "tactical_glove",
		r_arm = "tactical_glove",
		torso = "tactical_vest",
		legs = "tactical_pants",
		feet = "tactical_boots",
	},
	jolie = {
		head = "sunglasses",
		l_arm = "arm_warmer",
		r_arm = "arm_warmer",
		torso = "tank_top",
		legs = "skirt",
		feet = "sneakers",
	},
}

-- Format tables.
local fmt_people = {
	-- Put goober first, the rest in alphabetical order
	priority_keys = {"goober"}
}
local fmt_person = {
	-- Maintain the order used above
	priority_keys = {"head", "l_arm", "r_arm", "torso", "legs", "feet"}
}

-- Create, assign metatables
local _mt_people = {}
_mt_people.__index = _mt_people
_mt_people[tableToString.fmt_key] = fmt_people

local _mt_person = {}
_mt_person.__index = _mt_person
_mt_person[tableToString.fmt_key] = fmt_person


setmetatable(people, _mt_people)
for k, person in pairs(people) do
	setmetatable(person, _mt_person)
end

-- Format keys are read through the __index metamethod.
print(tableToString.convert(people))


-- Output:

--[[
return {
  goober = {
    head = "goo",
    l_arm = "goo",
    r_arm = "goo",
    torso = "goo",
    legs = "goo",
    feet = "goo",
  },
  bimmy = {
    head = "baseball_cap",
    l_arm = "wrist_watch",
    r_arm = "nothing",
    torso = "shirt",
    legs = "shorts",
    feet = "sandals",
  },
  jolie = {
    head = "sunglasses",
    l_arm = "arm_warmer",
    r_arm = "arm_warmer",
    torso = "tank_top",
    legs = "skirt",
    feet = "sneakers",
  },
  ripentear = {
    head = "tactical_helmet",
    l_arm = "tactical_glove",
    r_arm = "tactical_glove",
    torso = "tactical_vest",
    legs = "tactical_pants",
    feet = "tactical_boots",
  },
}
--]]
