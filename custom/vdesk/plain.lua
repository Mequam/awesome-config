vector = require "utils.vector"
awful = require "awful"
gears = require "gears"

PLAIN_DIMENSIONS = {2,2}
local START_POSITION = {0,0}


--gives each screen in the system a position indicating where it is currently
--looking, for convinence
local function create_screen_positions()
   awful.screen.connect_for_each_screen(
      function(s)
         s.desktop_position = START_POSITION
         print(s.desktop_position)
      end
   )
end

--keybinding used to indicate we want to move
local move_key = {"Mod1","Control"}

--convinence function that walks along the plain
--and loops over the edge
local function add_mod(plain_position,step)
   return vector.mod(
      vector.add(
         plain_position,step),
         PLAIN_DIMENSIONS
         )
end

--sets up the keys for walking around the plain
local function setup(keyset)
   --initilizes the positions on each of the screens
   create_screen_positions()

   --setup movement keys
   return gears.table.join(keyset,
         awful.key(move_key,"Up",function ()
            awesome.emit_signal("plain::walk",{0,1})
         end),
         awful.key(move_key,"Down",function ()
            awesome.emit_signal("plain::walk",{0,-1})
         end),
         awful.key(move_key,"Left",function ()
            awesome.emit_signal("plain::walk",{-1,0})
         end),
         awful.key(move_key,"Right",function ()
            awesome.emit_signal("plain::walk",{1,0})
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
         weight = weight * PLAIN_DIMENSIONS[d]
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
   for s=1,#PLAIN_DIMENSIONS do
      point_count = point_count * PLAIN_DIMENSIONS[s]
   end

   for s=0,point_count - 1 do
      local sum = s
      local tag = {}
      for d=1,#PLAIN_DIMENSIONS - 1 do
         tag[d] = sum % PLAIN_DIMENSIONS[d]
         sum = math.floor((sum - tag[d]) / PLAIN_DIMENSIONS[d])
      end
      tag[#PLAIN_DIMENSIONS] = sum
      
      --store the newly created vectors in a format the outside can use
      ret_val[s + 1] = vector.toString(tag)
   end

   return ret_val
end

local M = {}
   M.setup = setup
   M.create_tags = create_tags
   M.vector_mapping = vector_mapping
   M.add_mod = add_mod
return M
