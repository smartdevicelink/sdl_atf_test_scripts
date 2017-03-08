-- CASE 1: for locally run with "fab -H localhost tests_run"
-- Check substring "/appID_deviceMAC/storage/icon.png" with relative path of SDL, staring with ./
-- data.params.cmdIcon.value is received with UI.AddCommand
--
-- (string.match(data.params.cmdIcon.value, "%S*" .. "("..string.sub(storagePath, 2).."icon.png)" .. "%W*$") == nil )
--
-- Example:
-- searching substring '/SDL_bin/storage/0000001_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/icon.png' defined by (string.sub(storagePath, 2).."icon.png)
-- in string '/home/istoimenova/SmartDeviceLinkCore/test_run/SDL_bin/storage/0000001_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/icon.png' defined by (data.params.cmdIcon.value)

-- CASE 2: for CI
-- Check equal strings and works on CI and with absolute path of SDL
--
-- (data.params.cmdIcon.value ~= value_Icon )
--
-- Example:
-- compare string '/home/istoimenova/SmartDeviceLinkCore/test_run/SDL_bin/storage/0000001_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/icon.png' defined by (data.params.cmdIcon.value)
-- with string '/home/istoimenova/SmartDeviceLinkCore/test_run/SDL_bin/storage/0000001_12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0/icon.png' defined by (value_Icon)
--
-- Described solution makes scripts running on CI and locally

config.SDLStoragePath = commonPreconditions:GetPathToSDL() .. "storage/"
local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"

EXPECT_HMICALL("UI.AddCommand",
{
  cmdID = i,
  menuParams = { parentID = 0, position = 0, menuName ="Commandpositive" .. tostring(i)}
})
:ValidIf(function(_,data)
  local value_Icon = storagePath .. "icon.png"
  if (string.match(data.params.cmdIcon.value, "%S*" .. "("..string.sub(storagePath, 2).."icon.png)" .. "%W*$") == nil )  and
     (data.params.cmdIcon.value ~= value_Icon ) then
    print("\27[31m value of cmduIcon is WRONG. Expected: ".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
    return false
  else
    return true
  end
end)