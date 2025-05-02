local wibox = require "wibox"
local gears = require "gears"
local beautiful = require("beautiful")


-- syncs the color of the grid to match the given position
function sync_grid(grid,pos)
   local i = 1
   local grid_children = grid:get_children()

   for y = 1, PLAIN_DIMENSIONS[2] do
      for x = 1, PLAIN_DIMENSIONS[1] do
         print(grid_children[i])
         print(i)
         if pos[1] == x - 1 and pos[2] == y - 1 then
            print("red")
            grid_children[i]:set_bg("#FF0000")
         else
            print("blue")
            grid_children[i]:set_bg("#0000FF")
         end
         i = i + 1 --count to the index we need to find
      end
   end
end
-- syncs the grid to the given position
function create_grid(grid,width,height)
   for y = 1, PLAIN_DIMENSIONS[2] do
      for x = 1, PLAIN_DIMENSIONS[1] do
         print(x-1,y-1)

         ---- compute the color of the given topic on the given screen
         --local color = "#0000FF"

         --if pos[1] == x - 1 and pos[2] == y - 1 then
         --   color = "#FF0000"
         --end


         -- this is a single tile indicating which screen we are on
         local text_box = wibox.widget.textbox()
         text_box.focasable = false
         text_box:set_text("")
         --local text_box = wibox.widget {
         --   text = "",
         --   forced_width = 40,
         --   forced_height = 20,
         --   widget = wibox.widget.textbox
         --}

         -- give a color to the system
         --local color_box = wibox.widget {
         --            text_box,
         --            bg = "#0000FF",
         --            widget = wibox.container.background,
         --            forced_width = 40,
         --            forced_height = 20,
         --         }

         local color_box = wibox.container.background()
         color_box.widget = text_box
         color_box.bg = "#0000FF"
         color_box.forced_width = width
         color_box.forced_height = height
         color_box.focusable = false

         grid:add(color_box)
      end
   end
end

--debug function that creates a popup with the
--display grid
function grid_popup(grid)

   local grid_popup = awful.popup {
      widget =
      {
         grid,
         halign = "center",
         valign = "center",
         layout = wibox.container.place,
      },
       border_color = "#777777",
       border_width = 2,
       ontop = true,
       visible = true,
       placement = awful.placement.centered,
       --shape = gears.shape.rounded_rect,
       bg = "#222222",
       minimum_width = 400,
       minimum_height = 300,
       focusable = false
   }
end

--takes the screen that the grid widget will be on
--and returns the widget
function create_grid_widget(grid_screen,width,height)
   local grid = wibox.layout.grid()
   grid.forced_num_cols = 2
   grid.spacing = 3
   grid.focusable = false

   create_grid(grid,width,height)

   sync_grid(grid,grid_screen.topics[grid_screen.topic].position)




   awesome.connect_signal("plain::walk",function (step_dir)
      gears.timer.delayed_call(function ()
         grid_screen = awful.screen.focused()
         sync_grid(grid,grid_screen.topics[grid_screen.topic].position)

         -- force re-draw
         grid.visible = false
         grid.visible = true
      end)
   end)

   return grid
end

M = {}
M.create_grid_widget = create_grid_widget

return M
