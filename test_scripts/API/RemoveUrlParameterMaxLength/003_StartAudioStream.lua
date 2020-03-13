---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0200-Removing-URL-Param-Max-Length.md
--
-- Description: Check processing of Navigation.AudioStreamConsumer request with url length more than 500 characters
--
-- In case:
-- 1. AudioStreamConsumer is set to file value
-- 2. AudioStreamFile is set to value with length in 255 characters
-- 3. AppStorageFolder is set to value with length in 300 characters
-- 4. Audio service starts
-- SDL does:
-- - sends Navigation.StartAudioStream(<pathToSDL/AppStorageFolder>/<file name>)
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/RemoveUrlParameterMaxLength/commonRemoveUrlParameterMaxLength')

--[[ Local Variables ]]
local longStringInFileName = string.rep("u", 255)
local longPath = string.rep("u", 100) .."/" .. string.rep("u", 100).."/" .. string.rep("u", 100)
common.getConfigAppParams(1).appHMIType = { "NAVIGATION" }

--[[ Local Functions ]]
local function iniFilePreparation()
  common.setSDLIniParameter("AudioStreamConsumer", "file")
  common.setSDLIniParameter("AudioStreamFile", longStringInFileName)
  common.setSDLIniParameter("AppStorageFolder", longPath)
end

local function StartAudioStream()
  common.getMobileSession():StartService(10)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream",
        {
          url = config.pathToSDL .. longPath .. "/" .. longStringInFileName
        })
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Ini file preparation", iniFilePreparation)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")

common.Step("StartAudioStream", StartAudioStream)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

