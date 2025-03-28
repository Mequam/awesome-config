--this file contains the glue code that I use to connect
--different components and create virtual desktops that work
--the way I like
local plain = require "custom.vdesk.plain"
local awful = require "awful"
local fzf = require "custom.fzf"
local naughty = require "naughty"
local dcp = require "custom.dak_center_prompt"

-- global variables that represent the current master topic and point
-- screens can vary from this, and the math of the program is done per-screen,
-- however these serve as bookmarks for screens to bounce back to when
-- we reattach them to follow the rest of the system

dak_global_topic = "default"
dak_global_last_topic = "secondary"
dak_global_point = {0,0}

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

-- gets a list of topics for a given screen
function get_topic_options(screen)
   local fzf_options = {}
   local n = 0
   for k , _ in pairs(screen.topics) do
      n = n + 1
      fzf_options[n] = k
   end

   return fzf_options
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
   
   -- store the global topic as well
   if not screen.detached then
      dak_global_point = screen.topics[screen.topic].position
   end

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

-- returns true if the given tag name matches the
-- given topic
local function is_topic_tag(tag_name,topic)
   return tag_name:match('^' .. topic .. '-.*')
end

--takes a client and removes tags matching the topic of the current screen
--returns the new tags of the client for convinent usage
local function remove_topic_tags(topic,c)
   local tags = c:tags()
   local new_tags = {}

   -- remove the old tags from the client
   for k,tag in ipairs(tags) do
      if not (is_topic_tag(tag.name,topic)) then
         table.insert(new_tags,tag)
      end
   end

   c:tags(new_tags)
   
   return new_tags
end

-- convinence function to peel off the position
-- from one of our tags
local function get_tag_position(tag_name)
   local dash_index = string.find(tag_name,"-")
   return string.sub(tag_name,dash_index+1)
end

local function get_tag_topic(tag_name)
   local dash_index = string.find(tag_name,"-")
   return string.sub(tag_name,0,dash_index-1)
end

-- attempts to get the first tag from the client that
-- matches the given topic
local function get_client_topic_tag(topic,client)
   for _,tag in ipairs(client:tags()) do
      if is_topic_tag(tag.name,topic) then
         return tag
      end
   end
end

-- moves a client to the given topic
local function move_client_to_topic(to_topic,client)
   local start_screen = awful.screen.focused()
   if not start_screen then return end

   -- remove the old tags
   local new_tags = remove_topic_tags(start_screen.topic,client)

   -- add a tag in the new topic with the given position
   local new_tag = start_screen.topics[to_topic].tags[
      plain.vector_mapping(
         start_screen.topics[to_topic].position
      )
   ]
   table.insert(new_tags,new_tag)

   -- update the client tags to aim at the new topic
   client:tags(new_tags)


end

-- steps to the next screen,but takes the focused window with it
local function step_screen_with_window(screen,step_dir)
   c = client.focus
   if c then
      local new_tags = remove_topic_tags(screen.topic,c)
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
      local new_tags = remove_topic_tags(screen.topic,c)
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
local function switch_to_topic(s,topic)
   -- set each screen to the given topic
      s.last_topic = s.topic
      s.topic = topic

   -- store the global topic if this screen is part of the global
   -- topic space
      if not s.detached then
         dak_global_topic = topic
         dak_global_last_topic = s.last_topic
      end

      step_screen(s,{0,0}) --trick to focus on the new topics position
end

local function switch_to_topic_d(s,topic)
   detachify(switch_to_topic,s,topic)
end

local function go_to_last_topic(s)
   switch_to_topic(s,s.last_topic)
end

local function go_to_last_topic_d(s)
   detachify(go_to_last_topic,s,s.last_topic)
end

--detaches the current screen from our changing controls
local function detach(screen)

   screen.detached = not screen.detached
   local message = "detached current screen"

   if not screen.detached then
      message = "reatached current screen"
   end

   naughty.notify({ title = "dak topics", 
                    text = message,
                    timeout = 5})

   if not screen.detached then
      screen.topic = dak_global_topic
      screen.last_topic = dak_global_last_topic
      screen.topics[dak_global_topic].position = dak_global_point
      step_screen(screen,{0,0})
   end

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
                     detach(awful.screen.focused())
                  end),
                  awful.key({"Mod1","Control"},"a",function()
                     dcp.prompt("",
                        function (topic_name)
                           if topic_name ~= "" then
                              awful.screen.connect_for_each_screen(function (s2)
                                 create_topic(topic_name,s2)
                              end)

                              --if you just made the topic you probably
                              --want to switch to it
                              switch_to_topic_d(awful.screen.focused(),topic_name)
                           end
                     end)
                  end),
                  awful.key({"Mod4"},"Tab",function()
                           go_to_last_topic_d(awful.screen.focused(),choice)
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
                  
                  awful.key({"Mod4","Control"},"q",function ()
                     local client_to_move = client.focus
                     local screen = awful.screen.focused()
                     if client_to_move and screen then
                        local fzf_options = get_topic_options(screen)
                        fzf(fzf_options,function (choice)
                           move_client_to_topic(choice,client_to_move)
                           switch_to_topic_d(screen,choice)
                        end)
                     end
                  end
                  ),

                  awful.key({"Mod4"},"q",function()

                     local screen = awful.screen.focused()

                     if screen then

                        local fzf_options = get_topic_options(screen)
                        fzf(fzf_options,function (choice)
                              switch_to_topic_d(awful.screen.focused(),choice)
                        end)
                     end
                  end)
                  )
end

M = {}
   M.setup = setup
return M
