--This script contains common functions that are used in many script.
--How to use:
	--1. local SmartDeviceLinkConfigurations = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
	--2. SmartDeviceLinkConfigurations:GetValue(parameterName) --example
---------------------------------------------------------------------------------------------

local SmartDeviceLinkConfigurations = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

---------------------------------------------------------------------------------------------
------------------------------------------ Functions ----------------------------------------
---------------------------------------------------------------------------------------------
--List of functions:
--1. GetValue(parameterName)
--2. ReplaceString(originalString, replacedString)
---------------------------------------------------------------------------------------------


--1. GetValue(parameterName)
function SmartDeviceLinkConfigurations:GetValue(parameterName)

	findresult = string.find (config.pathToSDL, '.$')
	if string.sub(config.pathToSDL,findresult) ~= "/" then
		config.pathToSDL = config.pathToSDL..tostring("/")
	end

	-- Opens a file in read mode
	local file = io.open(config.pathToSDL .. "smartDeviceLink.ini", "r")
	local value = ""
	while true do

		local line = file:read()
		if line == nil then break end

		if string.find(line, parameterName) ~= nil then
			value = string.sub(line, string.find(line, "=") + 2 , string.len(line))
			break
		end
	end

	file:close()

	if value == "" then
		commonFunctions:printError(" smartDeviceLink.ini does not have parameter name: " ..  tostring(parameterName))
	end

	return value

end


--2. ReplaceString(originalString, replacedString)
function SmartDeviceLinkConfigurations:ReplaceString(originalString, replacedString)
  -- body
  local iniFilePath = config.pathToSDL .. "smartDeviceLink.ini"
  local iniFile = io.open(iniFilePath, "r")
  sContent = ""
  if iniFile then
    for line in iniFile:lines() do
        if line:match(originalString) then
        -- Text replacement
        line = string.gsub( line, originalString, replacedString )
        sContent = sContent .. line ..'\n'
      else
        sContent = sContent .. line .. '\n'
      end
    end
  end
  iniFile:close()

  iniFile = io.open(iniFilePath, "w")
  iniFile:write(sContent)
  iniFile:close()
end

return SmartDeviceLinkConfigurations