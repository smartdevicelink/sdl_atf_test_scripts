---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3321
--
-- Description:
-- Processing of the OnAppPropertiesChange notification to HMI on SetAppProperties request without one of nicknames
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Web app is enabled through SetAppProperties with two nicknames
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties
--  (without one of nicknames) of the policyAppID to SDL
--  a. SDL sends successful response to HMI
--  b. SDL sends BC.OnAppPropertiesChange notification with appropriate app properties parameters
--   (without one of nicknames) to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appProperties = {
  nicknames = { "nickname_11", "nickname_12" },
  policyAppID = "0000001",
  enabled = true,
  authToken = "authToken1",
  transportType = "transportType1",
  hybridAppPreference = "CLOUD",
  endpoint = "endpoint1"
}

local appPropertiesRemovedOneNickname = {
  nicknames = { "nickname_11" }, --removed nickname_12
  policyAppID = "0000001",
  enabled = true,
  authToken = "authToken1",
  transportType = "transportType1",
  hybridAppPreference = "CLOUD",
  endpoint = "endpoint1"
}


--[[ Local Variables ]]
local function onAppPropertiesChange(pData, pDataExpect, pTimes)
  common.setAppProperties(pData)
  common.onAppPropertiesChange(pDataExpect, pTimes)
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")

common.Step("OnAppPropertiesChange notification: added app properties with two nicknames",
  onAppPropertiesChange, { appProperties, appProperties })
common.Step("OnAppPropertiesChange notification: update app properties without one of nickname",
  onAppPropertiesChange, { appPropertiesRemovedOneNickname, appPropertiesRemovedOneNickname })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
