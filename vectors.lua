--this file contains a set of vector functions for basic
--vector math involving adding vectors
--it is primarily inteanded for creating virtual desktops inside of
--the awesome window manager
local function vectorfy(v1, v2,method)
   local ret_val = {}
   for k = 1, #v1 do
      table.insert(ret_val,method(v1[k],v2[k]))
   end
   return ret_val
end

local function add(v1,v2)
   return vectorfy(v1,v2,function (a,b) return a+b end)
end

local function modulus(v1,v2)
   return vectorfy(v1,v2,function (a,b) return a % b end)
end

local function toString(v)
   ret_val = ""
   for k = 1, #v do
      ret_val = ret_val .. v[k] .. ","
   end
   return ret_val
end

local M = {}
   M.add = add
   M.mod = modulus
   M.toString = toString

return M
