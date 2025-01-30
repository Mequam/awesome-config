vector = require "utils.vector"
awful = require "awful"
gears = require "gears"

Plain_user_position = {0,0}
Plain_max_dimensions = {2,2}

--convinence function that walks along the plain
--and loops over the edge
local function walk_plain(step)
   Plain_user_position =
      vector.mod(
         vector.add(
            Plain_user_position,step),
            Plain_max_dimensions
            )
   print(Plain_user_position[1])
   print(Plain_user_position[2])
   print()
end

--keybinding used to indicate we want to move
local move_key = {"Mod1","Control"}

local function setup_keys(keyset)
   --setup movement keys
   return gears.table.join(keyset,
         awful.key(move_key,"Up",function ()
            walk_plain({0,1})
         end),
         awful.key(move_key,"Down",function ()
            walk_plain({0,-1})
         end),
         awful.key(move_key,"Left",function ()
            walk_plain({-1,0})
         end),
         awful.key(move_key,"Right",function ()
            walk_plain({1,0})
         end)
   )
end

local M = {}
   M.setup_keys = setup_keys
return M
