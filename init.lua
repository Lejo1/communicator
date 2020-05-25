dofile(minetest.get_modpath(minetest.get_current_modname()).."crypto.lua")

local write = "com"
local errors = false
local chat = false

local channels = {}

local function chatcom()
  chat = true
  if not minetest.get_csm_restrictions().chat_messages then
    minetest.display_chat_message("Only .com avaible now, data will be transfered via chat")
  else minetest.display_chat_message("Sorry Chat is also restriced you can't use the Communicator :(")
  end
end

local function send(ch, msg)
  if not chat then
    if channels[ch] and channels[ch].m then
      if channels[ch].m:is_writeable() then
        if channels[ch].pw then
          local text = encrypt(channels[ch].pw, msg)
          channels[ch].m:send_all(text)
        else channels[ch].m:send_all(msg)
        end
        return true, "COM: #"..ch.." | <"..minetest.localplayer:get_name().."> "..msg
      else return false, "COM: Channel not writeable."
      end
    else return false, "COM: Channel doesn't exist"
    end
  elseif ch == write then
    local text = encrypt(channels[ch].pw, msg)
    minetest.send_chat_message(text)
    return true
  else return false, "COM: Only default channel possible when transfering via chat!"
  end
end

minetest.register_on_receiving_chat_message(function(msg)
  if not chat then
    return
  end
  local name, text = msg:match('^<([^>%s]+)>%s+(.*)$')
  if name and text then
    local succ, message = decrypt(channels[write].pw, text)
    if not succ then
      if not errors then
        return
      end
      message = "Error: "..message
    end
    minetest.display_chat_message("COM: #"..write.." | <"..name.."> "..tostring(message))
    return true
  end
end)

minetest.register_on_modchannel_message(function(channel_name, sender, message)
  if sender == "" then
    sender = "Server!"
  end
  if channels[channel_name].pw then
    succ, message = decrypt(channels[channel_name].pw, message)
    if not succ then
      if not errors then
        return
      end
      message = "Error: "..message
    end
  end
  minetest.display_chat_message("COM: #"..channel_name.." | <"..sender.."> "..message)
end)

minetest.register_on_modchannel_signal(function(channel_name, signal)
  minetest.display_chat_message("COM: Signal on channel:"..channel_name.." | Signal: "..signal)
  if signal == 0 then
    minetest.display_chat_message("COM: Joined channel: "..channel_name)
  elseif signal == 1 then
    minetest.display_chat_message("COM: Failed to join channel: "..channel_name.." | Seams to be disabled by server")
    chatcom()
    channels[channel_name] = nil
  elseif signal == 2 then
    minetest.display_chat_message("COM: Left channel: "..channel_name)
    channels[channel_name] = nil
  elseif signal == 3 then
    minetest.display_chat_message("COM: Failed to leave channel: "..channel_name)
  end
end)

minetest.register_chatcommand("join_channel", {
  params = "<channel_name> <pw>",
  description = "Joins an additional channel with optional password(must be 16 bit)",
  func = function(params)
    local d = string.split(params, " ")
    local c, pw = d[1], d[2]
    channels[c] = {m=minetest.mod_channel_join(c), pw=make_key(pw)}
  end
})

minetest.register_chatcommand("leave_channel", {
  params = "<channel_name>",
  description = "Leaves an channel",
  func = function(param)
    if channels[param] then
      channels[param].m:leave()
    else return false, "COM: Channel doesn't exist"
    end
  end
})

minetest.register_chatcommand("c", {
  params = "<msg>",
  description = "Send message to the com mod_channel",
  func = function(param)
    return send(write, param)
  end
})

minetest.register_chatcommand("p", {
  params = "<channel> <msg>",
  description = "Send message to the specific channel",
  func = function(params)
    local channel, msg = params:match("(%S+)%s+(.+)")
    if channel and msg then
      return send(channel, msg)
    else return false, "COM: Invalid usage"
    end
  end
})

channels[write] = {m=minetest.mod_channel_join(write), pw=make_key("coolmodsneedcoolpasswords")}

minetest.after(3, function()
  if not channels[write] or not channels[write].m or not channels[write].m:is_writeable() then
    minetest.display_chat_message("Mod Channel seam to be disabled by server")
    chatcom()
  end
end)
