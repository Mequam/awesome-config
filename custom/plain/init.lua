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
end

--keybinding used to indicate we want to move
local move_key = {"Mod1","Control"}

local function setup_keys(keyset)
   --setup movement keys
   return gears.table.join(keyset,
         awful.key(move_key,"Up",function ()
            walk_plain({0,1})
            awesome.emit_signal("plain::walk","Up")
         end),
         awful.key(move_key,"Down",function ()
            walk_plain({0,-1})
            awesome.emit_signal("plain::walk","Down")
         end),
         awful.key(move_key,"Left",function ()
            walk_plain({-1,0})
            awesome.emit_signal("plain::walk","Left")
         end),
         awful.key(move_key,"Right",function ()
            walk_plain({1,0})
            awesome.emit_signal("plain::walk","Right")
         end)
   )
end

--takes in a vector and returns an
--integer mapping for that vector
--this is inteanded to be the array mapping for the vector
--so we can access and store it easier in the tag list of
--the screen
local function vector_mapping(v)
   local ret_val = 0
   
   for s = 1, #v do
      local weight = 1

      for d = 1, s-1 do
         weight = weight * Plain_max_dimensions[d]
      end

      ret_val = ret_val + v[s]*weight
   end
   
   return ret_val+1 --stupid lua one indexing >:[
end
--returns a list of tags for our given
--screen dimensions to be used for additional processing
local function create_tags()
   local ret_val = {}
   local point_count = 1
   for s=1,#Plain_max_dimensions do
      point_count = point_count * Plain_max_dimensions[s]
   end

   for s=0,point_count - 1 do
      local sum = s
      local tag = {}
      for d=1,#Plain_max_dimensions - 1 do
         tag[d] = sum % Plain_max_dimensions[d]
         sum = math.floor((sum - tag[d]) / Plain_max_dimensions[d])
      end
      tag[#Plain_max_dimensions] = sum
      
      --store the newly created vectors in a format the outside can use
      ret_val[s + 1] = vector.toString(tag)
   end

   return ret_val
end

local M = {}
   M.setup_keys = setup_keys
   M.create_tags = create_tags
   M.vector_mapping = vector_mapping
return M
