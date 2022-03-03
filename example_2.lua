--[[
	tableToString: An example of using format tables to prioritize the order of certain keys.
--]]

local tableToString = require("table_to_string")


-- The table to serialize.
local rooms = {
	{
		name = "Red room",
		location = "North",
		boxes = {
			{x=0, y=0, w=16, h=16},
			{y=144, w=24, h=12, x=28},
			{w=32, h=32, x=144, y=96},
			{h=4, x=68, y=86, w=2},
		}
	}, {
		name = "Green room",
		location = "West",
		boxes = {
			{x=9, y=44, w=11, h=11},
			{y=28, w=12, h=14, x=160},
			{h=24, x=70, y=22, w=64},
		}
	}, {
		boxes = {
			{w=128, h=128},
		},
		location = "North-West",
		name = "Blue room"
	}
}

-- Format tables.
local fmt_box = {
	missing_pri_key = "warn", -- "warn" for message, "error" to stop the script, nil to be quiet.
	priority_keys = {"x", "y", "w", "h"}
}
local fmt_room = {
	priority_keys = {"name", "location", "boxes"}
}

-- Assign format tables
for i, room in ipairs(rooms) do
	tableToString.setFormatTable(room, fmt_room, false)
	for j, box in ipairs(room.boxes) do
		tableToString.setFormatTable(box, fmt_box, false)
	end
end

local str = tableToString.convert(rooms)

-- Recursively remove format tables.
tableToString.scrubFormatTable(rooms, true)

print(str)

-- Output:
--[[
Warning: Missing priority key: x -- caused by the one box in Blue Room
Warning: Missing priority key: y
return {
  {
    name = "Red room",
    location = "North",
    boxes = {
      {
        x = 0,
        y = 0,
        w = 16,
        h = 16,
      }, {
        x = 28,
        y = 144,
        w = 24,
        h = 12,
      }, {
        x = 144,
        y = 96,
        w = 32,
        h = 32,
      }, {
        x = 68,
        y = 86,
        w = 2,
        h = 4,
      }, 
    },
  }, {
    name = "Green room",
    location = "West",
    boxes = {
      {
        x = 9,
        y = 44,
        w = 11,
        h = 11,
      }, {
        x = 160,
        y = 28,
        w = 12,
        h = 14,
      }, {
        x = 70,
        y = 22,
        w = 64,
        h = 24,
      }, 
    },
  }, {
    name = "Blue room",
    location = "North-West",
    boxes = {
      {
        w = 128,
        h = 128,
      }, 
    },
  }, 
}

--]]

