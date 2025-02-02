--this file contains the glue code that I use to connect
--different components and create virtual desktops that work
--the way I like
local plain = require "custom.vdesk.plain"
local awful = require "awful"
local vector = require "utils.vector"
local naughty = require "naughty"



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
function step_screen(screen,step_dir)
   screen.desktop_position = plain.add_mod(
                                    screen.desktop_position,
                                    step_dir)
   --we only move this screen
   local tag = screen.tags[
                           plain.vector_mapping(screen.desktop_position)
                           ]
   if tag then
      tag:view_only()
   end
end

--called when the user wants to walk along the current
--desktop plain
awesome.connect_signal("plain::walk",function (step_dir)
   local screen = awful.screen.focused()
   if screen.detached then
      step_screen(screen,step_dir)
   else
      --we try and move EVERY screen
      --that is not detatched
      awful.screen.connect_for_each_screen(function(s)
            if not s.detached then
               step_screen(s,step_dir)
            end
      end)
   end
end
)

local function setup(keycarry)
   --initilize the screen positions
   keycarry = plain.setup(keycarry)
   awful.screen.connect_for_each_screen(function(s)
      s.detatched = false
      step_screen(s,{0,0}) --trick to focus on the first tag on the given screen
   end)
   return gears.table.join(keycarry,
                  awful.key({"Mod1","Control"},"d",function()
                     local screen = awful.screen.focused()
                     screen.detached = not screen.detached
                     naughty.notify({ title = "debug", text = "detached",timeout = 0})
                  end))
end

M = {}
   M.setup = setup
   M.add_topic_tags = add_topic_tags
return M
