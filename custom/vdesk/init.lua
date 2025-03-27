--this file contains the glue code that I use to connect
--different components and create virtual desktops that work
--the way I like
local plain = require "custom.vdesk.plain"
local awful = require "awful"
local vector = require "utils.vector"
local fzf = require "custom.fzf"
local naughty = require "naughty"
local dcp = require "custom.dak_center_prompt"


--adds virtual desktop tags that are contain a topic to the given
--screen
local function add_topic_tags(topic,s)
   local tags = plain.create_tags()
   for i=1,#tags do
      local t = awful.tag.add(topic .. "-" .. tags[i], {
                     screen = s,
                     layout = awful.layout.suit.tile
                  })
      table.insert(s.topics[topic].tags,t)
   end
end

local function step_screen(screen,step_dir)
   screen.topics[screen.topic].position = plain.add_mod(
                                    screen.topics[screen.topic].position,
                                    step_dir)
   --we only move this screen
   local tag = screen.topics[screen.topic].tags[
                           plain.vector_mapping(
                                 screen.topics[screen.topic].position
                              )
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
--creates a topic and adds its tags to a given screen
local function create_topic(topic,s)
   if not s.topics then
      s.topics = {}
   end

   print("creating topic " .. topic)

   s.topics[topic] = {
      position = {0,0},
      tags = {}
   }
   add_topic_tags(topic,s)
end

--switches to a given topic
--if you want per screen topic switching this is a good place
--to do it
local function switch_to_topic(topic)
   -- set each screen to the given topic
   awful.screen.connect_for_each_screen(function(s)
      s.topic = topic
      step_screen(s,{0,0}) --trick to focus on the new topics position
   end)
end

local function setup(keycarry)
   --initilize the screen positions

   dcp.setup()
   keycarry = plain.setup(keycarry)
   awful.screen.connect_for_each_screen(function(s)
      
      s.topics = {}
      s.topic = "default"
      
      create_topic("default",s)
      create_topic("secondary",s)

      s.detatched = false
      step_screen(s,{0,0}) --trick to focus on the first tag on the given screen
   end)
   return gears.table.join(keycarry,
                  awful.key({"Mod1","Control"},"d",function()
                     
                     local screen = awful.screen.focused()
                     screen.detached = not screen.detached
                     naughty.notify({ title = "debug", text = "detached",timeout = 0})

                  end),
                  awful.key({"Mod1","Control"},"a",function()
                     dcp.prompt("",
                        function (topic_name)
                           if topic_name ~= "" then
                              awful.screen.connect_for_each_screen(function (s2)
                                 create_topic(topic_name,s2)
                              end)
                           end
                     end)
                  end),
                  awful.key({"Mod4"},"q",function()

                     local screen = awful.screen.focused()
                     
                     print(screen.topics)

                     -- the rest of the code expects topics to be global,
                     -- but they are stored per-screen, so in the future
                     -- if you wanted to do some kind of per screen topic
                     -- manipulation that capability is supported
                     

                     if screen then

                        local fzf_options = {}
                        local n = 0
                        for k , _ in pairs(screen.topics) do
                           n = n + 1
                           fzf_options[n] = k
                        end

                        fzf(fzf_options,function (choice)
                           switch_to_topic(choice)
                        end)
                     end
                  end)
                  )
end

M = {}
   M.setup = setup
return M
