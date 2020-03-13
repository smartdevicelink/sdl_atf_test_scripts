---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the GetAppProperties request from HMI (with parameter, with omitted policyAppID parameter)
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties of the policyAppID1 to SDL
--  a. SDL sends successful response to HMI
-- 2. HMI sends BC.SetAppProperties request with application properties of the policyAppID2 to SDL
--  a. SDL sends successful response to HMI
-- 3. HMI sends BC.GetAppProperties request with policyAppID1 to SDL
--  a. SDL sends successful response with application properties of the policyAppID1 to HMI
-- 4. HMI sends BC.GetAppProperties request with policyAppID2 to SDL
--  a. SDL sends successful response with application properties of the policyAppID2 to HMI
-- 5. HMI sends BC.GetAppProperties request with omitted policyAppID parameter to SDL
--  a. SDL sends successful response with all applications properties ( policyAppID1, policyAppID2 ) to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appProperties1 = {
  nicknames = { "Test Web Application_11" },
  policyAppID = "0000001",
  enabled = true,
  authToken = "ABCD12345",
  transportType = "WS",
  hybridAppPreference = "CLOUD",
  endpoint = "ws://127.0.0.1:8080/"
}

local appProperties2 = {
  nicknames = { "Test Web Application_21", "Test Web Application_22" },
  policyAppID = "0000002",
  enabled = false
}

--[[ Local Functions ]]
local function getAppPropertiesAll(pData)
  local sdlResponseDataResult = {}
  sdlResponseDataResult.code = 0
  sdlResponseDataResult.properties =  pData
  local corId = common.getHMIConnection():SendRequest("BasicCommunication.GetAppProperties", {})
  common.getHMIConnection():ExpectResponse(corId, { result = sdlResponseDataResult })
  :ValidIf(function(_,data)
    return common.validation(data.result.properties, sdlResponseDataResult.properties,
      "BasicCommunication.GetAppProperties")
  end)
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
common.Step("SetAppProperties request for policyAppID1", common.setAppProperties, { appProperties1 })
common.Step("SetAppProperties request for policyAppID2", common.setAppProperties, { appProperties2 })

common.Title("Test")
common.Step("GetAppProperties request: with policyAppID1", common.getAppProperties,
  { appProperties1 })
common.Step("GetAppProperties request: with policyAppID2", common.getAppProperties,
  { appProperties2 })
common.Step("GetAppProperties request: policyAppID is missing", getAppPropertiesAll,
  {{ appProperties1, appProperties2 }})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
