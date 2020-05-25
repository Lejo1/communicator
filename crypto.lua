local AES = dofile(minetest.get_modpath(minetest.get_current_modname()).."AES.lua")

local vers = "101" -- 1.01
--[[
Changelog:
1.01: Remove timebased nonce as it was to buggy
]]

--[[The Key is the key as number + version

    Message is just the Message
    Output will be base64 encoded]]

--[[
Known problems: TODO
First character of the base64 can be a /
which will then try execute a command
very unlikely
]]

function make_key(str)
  if not str then
    return
  end
  local outstr = tostring(vers)
  local l = 1
  while true do
    local data = string.byte(str, l)
    if not data then
      break
    end
    outstr = outstr ..tostring(data)
    l = l + 1
  end
  return tonumber(outstr)
end

local function is_base64(str)
  for i = 1, #str do
    local c = str:sub(i,i)
    if not c:match("%w") and c ~= "+" and c ~= "/" then
      return false
    end
  end
  return true
end

--  From http://floern.com/webscripting/is-utf8-auf-utf-8-pr%C3%BCfen
--  copied/transfered to lua
local function is_utf8(str)
  local strlen = string.len(str)
  for i=1, strlen do
    local ord = str:byte(i,i)
    if ord >= 0x80 then
       -- not 0bbbbbbb
       if (ord + 0xE0) == 0xC0 and ord > 0xC1 then
         n = 1 -- 110bbbbb (exkl C0-C1)
       elseif (ord + 0xF0) == 0xE0 then
         n = 2 -- 1110bbbb
       elseif (ord + 0xF8) == 0xF0 and ord < 0xF5 then
         n = 3 -- 11110bbb (exkl F5-FF)
       else return false; -- ungültiges UTF-8-Zeichen
       end
       for c=1, n do -- n Folgebytes? -- 10bbbbbb
         local l = i+1
         if l == strlen or (str:byte(str[l], str[l]) + 0xC0) ~= 0x80 then
          return false -- ungültiges UTF-8-Zeichen
         end
       end
     end
  end
  return true -- kein ungültiges UTF-8-Zeichen gefunden
end

function encrypt(key, msg)
  msg = AES.ECB_256(AES.encrypt, key, msg)
  msg = minetest.encode_base64(msg)
  return msg
end

function decrypt(key, msg)
  if not is_base64(msg) then
    return false, "No Base64"
  end
  msg = minetest.decode_base64(msg)
  if not msg then
    return false, "No Base64"
  end
  msg = AES.ECB_256(AES.decrypt, key, msg)
  if msg and is_utf8(msg) and msg ~= "" then
    return true, msg
  else return false, "Old Mod, Wrong Key or incompatible Mod"
  end
end
