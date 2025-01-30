--this file contains the glue code that I use to connect
--different components and create virtual desktops that work
--the way I like
local plain = require "custom.plain"
local awful = require "awful"
local vector = require "utils.vector"

--adds virtual desktop tags that are contain a topic to the given
--screen
local function add_topic_tags(topic,s)
   local tags = plain.create_tags()
   for i=1,#tags do
      awful.tag.add(topic .. "-" .. tags[i], {
                     screen = s,
                     layout = awful.layout.suit.tile
                  })
   end
end

awesome.connect_signal("plain::walk",function (step_dir)
   local screen = awful.screen.focused()
   local tag = screen.tags[plain.vector_mapping(Plain_user_position)]
   if tag then
      tag:view_only()
   end
end)

local function setup_keys(keycarry)
   return plain.setup_keys(keycarry)
end

M = {}
   M.setup_keys = setup_keys
   M.add_topic_tags = add_topic_tags
return M
