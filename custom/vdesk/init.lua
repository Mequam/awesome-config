--this file contains the glue code that I use to connect
--different components and create virtual desktops that work
--the way I like
local plain = require "custom.vdesk.plain"
local awful = require "awful"
local vector = require "utils.vector"
local fzf = require "custom.fzf"
local naughty = require "naughty"
local wibox = require "wibox"
local beautiful = require("beautiful")


topic = "secondary"

-- Create a shortcut function
local function echo_test()
   local screen = awful.screen.focused()
   print(screen.text_prompt)
   if screen then
      print("prompting")
      awful.prompt.run {
        prompt       = "topic name: ",
        textbox      = screen.text_prompt.widget,
        exe_callback = function(input)
                           print(input)
                        end,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
      }
      --awful.prompt.run {
      --   prompt = "topic",
      --   text = "",
      --   bg_cursor = "#ff0000",
      --   textbox = screen.mypromptbox,
      --   exec_callback = function(input)
      --      print(input)
      --   end
      --}
   end
    --awful.prompt.run {
    --    prompt       = '<b>Echo: </b>',
    --    text         = 'default command',
    --    bg_cursor    = '#ff0000',
    --    -- To use the default rc.lua prompt:
    --    --textbox      = mouse.screen.mypromptbox.widget,
    --    textbox      = atextbox,
    --    exe_callback = function(input)
    --        if not input or #input == 0 then return end
    --        naughty.notify{ text = 'The input was: '..input }
    --    end
    --}
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
function step_screen(screen,step_dir)
   screen.topics[topic].position = plain.add_mod(
                                    screen.topics[topic].position,
                                    step_dir)
   for k, v in pairs(screen.tags) do
      print(k,v)
   end
   --we only move this screen
   local tag = screen.topics[topic].tags[
                           plain.vector_mapping(screen.topics[topic].position)
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

   s.topics[topic] = {
      position = {0,0},
      tags = {}
   }
   add_topic_tags(topic,s)
end
local function setup(keycarry)
   --initilize the screen positions
   keycarry = plain.setup(keycarry)
   awful.screen.connect_for_each_screen(function(s)

      local text_prompt = awful.widget.prompt(
         {
            font = "Martian Mono Nerd Font 20",
            bg = beautiful.bg_systray
         }
      )

      local text_wibox = wibox({
         width = 300,
         height = 100,
         visible = true,
         ontop = true,
         bg = beautiful.bg_systray,
         fg = beautiful.fg_normal,
         halign = "center",
         valign = "center"
      })

      text_wibox:setup {
         {
            text_prompt,
            halign = "center",
            valign = "center",
            widget = wibox.container.place
         },
         layout = wibox.layout.stack
      }

      awful.placement.centered(text_wibox)

      

      --local popup = awful.popup()
      --popup:add(text_prompt)
      --popup.screen = s
      --local text_prompt = awful.popup {
      --    widget = {
      --        {
      --            {
      --                text   = 'foobar',
      --                widget = wibox.widget.textbox,
      --                font = "Martian Mono Nerd Font 20"
      --            },
      --            layout = wibox.layout.fixed.vertical,
      --        },
      --        margins = 10,
      --        widget  = wibox.container.margin
      --    },
      --    border_width = 0,
      --    placement    = awful.placement.centered,
      --    shape        = function (cr,width,height)
      --                     gears.shape.rectangle(cr,width,height) 
      --                   end,
      --    visible      = false,
      --    screen = s
      --}
      
      s.text_prompt = text_prompt
      s.topics = {}
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
                     echo_test()
                    -- fzf({"test","test2","test3"},function (choice)
                    --    print(choice)
                    -- end)
                  end)
                  )

end

M = {}
   M.setup = setup
return M
