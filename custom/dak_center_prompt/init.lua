local beautiful = require("beautiful")
local wibox = require "wibox"
local gears = require "gears"

-- Create a shortcut function to hide and unhide prompt
local function dak_center_prompt(prompt,callback)
   local screen = awful.screen.focused()
   
   if screen then
      screen.dak_center_prompt_container.visible = true
      awful.prompt.run {
        prompt       = prompt,
        textbox      = screen.dak_center_prompt.widget,
        exe_callback = function (data)
                           callback(data)
                           screen.dak_center_prompt_container.visible = false
                       end,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
      }
   end

end

local has_ran_setup_for_dak_prompt = false

-- called to setup the prompt
-- for a given screen
local function setup(s2)
   --make sure we run this as a singleton
   if has_ran_setup_for_dak_prompt then return end
   has_ran_setup_for_dak_prompt = true

   awful.screen.connect_for_each_screen(function (s)
      local text_prompt = awful.widget.prompt(
         {
            font = "Martian Mono Nerd Font 20",
            bg = beautiful.bg_systray
         }
      )

      local text_wibox = wibox({
         width = 300,
         height = 100,
         visible = false,
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

      data = {
         x=s.geometry.x,
         y=s.geometry.y,
         width=s.geometry.width,
         height=s.geometry.height
      }

      text_wibox.x = s.workarea.x + (s.workarea.width - text_wibox.width) / 2
      text_wibox.y = s.workarea.y + (s.workarea.height - text_wibox.height) / 2

      --awful.placement.centered(text_wibox, {
      --   parent = data --make sure its per screen
      --})

      s.dak_center_prompt = text_prompt
      s.dak_center_prompt_container = text_wibox

      return keycarry
   end) --foreach screen
end


-- properly export the different variables
M = {}

M.prompt = dak_center_prompt
M.setup = setup

return M
