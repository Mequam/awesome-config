local fzf_pid = 0

--stolen from the lua docs to remove space in a string
--from the front and back of the string
function trim(s)
   return s:sub(1,-2)
end

--this function takes in a set of options and a callback
--method, and performs fuzzy finding on those options
local function fuzzy_find_topics(options,callback)
   --gaurd statement to avoid breaking things
   if fzf_pid ~=0 then return end
   
   local option_string = ""

   for k = 2, #options do
      option_string = options[k] .. "," .. option_string
   end
   if options[1] then
      option_string = option_string .. options[1]
   end

   print(option_string)

   fzf_pid = awful.spawn.easy_async(string.format(
                                       "terminator -e '~/.config/awesome/scripts/fzf_options.sh %s'",
                                       option_string
                                       ),
   function()
      awful.spawn.easy_async_with_shell("cat /tmp/topic",function (result)
         callback(trim(result))
      end)
   end)
end

client.connect_signal("manage",function (c)
   print(c.pid)
   if fzf_pid ~= 0 and c.pid == fzf_pid then
      print("fullscreen!")
      c.fullscreen = true
      fzf_pid = 0
   end
end)


return fuzzy_find_topics
