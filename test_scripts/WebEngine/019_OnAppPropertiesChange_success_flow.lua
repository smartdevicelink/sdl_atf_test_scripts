---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the OnAppPropertiesChange notification to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties
--  (only mandatory, all parameters, the same parameters ) of the policyAppID to SDL
--  a. SDL sends successful response to HMI
--  b. SDL sends BC.OnAppPropertiesChange notification with appropriate app properties parameters to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local notExpected = 0

local appProperties = {
    policyAppID = "0000001"
}

local appPropertiesExpect = {
  policyAppID = "0000001",
  enabled = false,
  nicknames = common.EMPTY_ARRAY
}

local appProperties1 = {
  nicknames = { "nickname_11", "nickname_12" },
  policyAppID = "0000001",
  enabled = true,
  authToken = "authToken1",
  transportType = "transportType1",
  hybridAppPreference = "CLOUD",
  endpoint = "endpoint1"
}

local appProperties2 = {
  nicknames = { "nickname_22", "nickname_21" },
  policyAppID = "0000001",
  enabled = false,
  authToken = "authToken2",
  transportType = "transportType2",
  hybridAppPreference = "BOTH",
  endpoint = "endpoint2"
}

local appProperties3 = {
  nicknames = common.EMPTY_ARRAY,
  policyAppID = "0000001",
  enabled = false,
  authToken = "authToken2",
  transportType = "transportType2",
  hybridAppPreference = "BOTH",
  endpoint = "endpoint2"
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
common.Step("OnAppPropertiesChange notification: added only mandatory app properties parameter",
  onAppPropertiesChange, { appProperties, appPropertiesExpect })

common.Step("OnAppPropertiesChange notification: added all app properties parameters",
  onAppPropertiesChange, { appProperties1, appProperties1 })

common.Step("OnAppPropertiesChange notification: update all app properties parameters",
  onAppPropertiesChange, { appProperties2, appProperties2 })

common.Step("OnAppPropertiesChange notification: update with the same app properties parameters",
  onAppPropertiesChange, { appProperties2, appProperties2, notExpected })

common.Step("OnAppPropertiesChange notification: update with the empty nicknames",
  onAppPropertiesChange, { appProperties3, appProperties3 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
