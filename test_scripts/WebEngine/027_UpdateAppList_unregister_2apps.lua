---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the UpdateAppList request to HMI if Web application is unregistered
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Web WebApp_1 is enabled through SetAppProperties
-- 3. Web WebApp_2 is enabled through SetAppProperties
-- 4. Web WebApp_1 is registered and activated

-- Sequence:
-- 1. Web app is unregistered
--  a. SDL sends BC.UpdateAppList with WebApp_1 and WebApp_2 since they are still enabled
---------------------------------------------------------------------------------------------------
--[[ General test configuration ]]
config.defaultMobileAdapterType = "WS"

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{ webSocketServerSupport = { "ON" }}}

--[[ Local Variables ]]
local expected = 1

--[[ Local Functions ]]
local function setAppProperties(pAppId, pEnabled, pTimes, pExpNumOfApps)
  local webAppProperties = {
    nicknames = { "Test Application" },
    policyAppID = "000000" .. pAppId,
    enabled = pEnabled,
    transportType = "WS",
    hybridAppPreference = "CLOUD"
  }
  common.setAppProperties(webAppProperties)
  common.checkUpdateAppList(webAppProperties.policyAppID, pTimes, pExpNumOfApps)
end

local function unregisterApp(pAppID, pTimes, pExpNumOfApps)
  local cid = common.getMobileSession(1):SendRPC("UnregisterAppInterface", {})
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  common.checkUpdateAppList("000000" .. pAppID, pTimes, pExpNumOfApps)
end

local function registerApp(pAppID, pTimes, pExpNumOfApps)
  common.registerAppWOPTU(1, 1)
  common.checkUpdateAppList("000000" .. pAppID, pTimes, pExpNumOfApps)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("UpdateAppList on setAppProperties for policyAppID1:enabled=true",
  setAppProperties, { 1, true, expected, 1 })
common.Step("UpdateAppList on setAppProperties for policyAppID2:enabled=true",
  setAppProperties, { 2, true, expected, 2 })
common.Step("RAI of web App1", registerApp, { 2, expected, 2 })
common.Step("Activate web app1", common.activateApp, { 1 })
common.Step("Unregister App1", unregisterApp, { 2, expected, 2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
