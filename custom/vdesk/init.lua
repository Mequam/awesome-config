--this file contains the glue code that I use to connect
--different components and create virtual desktops that work
--the way I like
local plain = require "custom.vdesk.plain"
local awful = require "awful"
local fzf = require "custom.fzf"
local naughty = require "naughty"
local dcp = require "custom.dak_center_prompt"

-- higher order convinence function that encodes the logic
-- of doing something for detached screens or not at all
function detachify(callback,screen,arg)
   if screen.detached then
      callback(screen,arg)
   else
      --we try and move EVERY screen
      --that is not detatched
      awful.screen.connect_for_each_screen(function(s)
            if not s.detached then
               callback(s,arg)
            end
      end)
   end
end

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
      return tag
   end
end

-- convinence function that steps screen and respects
-- the detach operator
local function step_screen_d(screen,step_dir)
   detachify(step_screen,screen,step_dir)
   -- get the current tag of the screen for return value
   return step_screen(screen,{0,0})
end

--takes a client and removes tags matching the topic of the current screen
--returns the new tags of the client for convinent usage
local function remove_topic_tags(screen,c)
   local tags = c:tags()
   local new_tags = {}

   -- remove the old tags from the client
   for k,tag in ipairs(tags) do
      if not (tag.name:match('^' .. screen.topic .. '-.*')) then
         table.insert(new_tags,tag)
      end
   end

   c:tags(new_tags)
   
   return new_tags
end

-- steps to the next screen,but takes the focused window with it
local function step_screen_with_window(screen,step_dir)
   c = client.focus
   if c then
      local new_tags = remove_topic_tags(screen,c)
      local current_desktop_tag = step_screen(screen,step_dir)

      table.insert(new_tags,current_desktop_tag)

      --update the tags to include the new ones
      c:tags(new_tags)
   end
end

-- steps to the next screen, with focused window, and pulls other screens
local function step_screen_with_window_d(screen,step_dir)
   c = client.focus
   if c then
      local new_tags = remove_topic_tags(screen,c)
      local current_desktop_tag = step_screen_d(screen,step_dir)

      table.insert(new_tags,current_desktop_tag)

      --update the tags to include the new ones
      c:tags(new_tags)
   end
end


--called when the user wants to walk along the current
--desktop plain
awesome.connect_signal("plain::walk",function (step_dir)
   detachify(step_screen,awful.screen.focused(),step_dir)
end
)
--creates a topic and adds its tags to a given screen
local function create_topic(topic,s)
   if not s.topics then
      s.topics = {}
   end

   s.topics[topic] = {
      position = {0,0},
      tags = {}
   }
   add_topic_tags(topic,s)
end

--switches to a given topic
--if you want per screen topic switching this is a good place
--to do it
local function switch_to_topic(topic,s)
   -- set each screen to the given topic
      s.last_topic = s.topic
      s.topic = topic
      step_screen(s,{0,0}) --trick to focus on the new topics position
end

local function go_to_last_topic(topic,s)
   switch_to_topic(s.last_topic,s)
end

local function setup(keycarry)
   --initilize the screen positions

   dcp.setup()
   keycarry = plain.setup(keycarry)
   awful.screen.connect_for_each_screen(function(s)
      
      s.topics = {}
      s.topic = "default"
      s.last_topic = "secondary"
      
      create_topic("default",s)
      create_topic("secondary",s)

      s.detatched = false
      step_screen(s,{0,0}) --trick to focus on the first tag on the given screen
   end)
   return gears.table.join(keycarry,
                  awful.key({"Mod1","Control"},"d",function()
                     
                     local screen = awful.screen.focused()
                     screen.detached = not screen.detached
                     naughty.notify({ title = "dak topics", 
                                      text = "detached current screen",
                                      timeout = 0})

                  end),
                  awful.key({"Mod1","Control"},"a",function()
                     dcp.prompt("",
                        function (topic_name)
                           if topic_name ~= "" then
                              awful.screen.connect_for_each_screen(function (s2)
                                 create_topic(topic_name,s2)
                                 --if you just made the topic you probably
                                 --want to switch to it
                                 switch_to_topic(topic_name,s2)
                              end)
                           end
                     end)
                  end),
                  awful.key({"Mod4"},"Tab",function()
                        awful.screen.connect_for_each_screen(function(s)
                           go_to_last_topic(choice,s)
                        end
                        )
                     end
                  ),
                  --move a window with you over virtual desktops
                  --gotta really GRAB the window to move it
                  awful.key({"Mod4","Mod1","Shift","Control"},"Left", function ()
                     step_screen_with_window_d(awful.screen.focused(),{-1,0})
                  end),
                  awful.key({"Mod4","Mod1","Shift","Control"},"Right", function ()
                     step_screen_with_window_d(awful.screen.focused(),{1,0})
                  end),
                  awful.key({"Mod4","Mod1","Shift","Control"},"Down", function ()
                     step_screen_with_window_d(awful.screen.focused(),{0,-1})
                  end),
                  awful.key({"Mod4","Mod1","Shift","Control"},"Up", function ()
                     step_screen_with_window_d(awful.screen.focused(),{0,1})
                  end),

                  --actually I think all of the above vectors are mathmatically
                  --equivilent in the modulus space we move in, but it pays to have
                  --consistency :D

                  awful.key({"Mod4"},"q",function()

                     local screen = awful.screen.focused()
                     
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
                           awful.screen.connect_for_each_screen(function(s)
                              switch_to_topic(choice,s)
                           end
                        )
                        end)
                     end
                  end)
                  )
end

M = {}
   M.setup = setup
return M
