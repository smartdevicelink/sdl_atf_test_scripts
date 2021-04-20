---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the UpdateAppList request to HMI if Web application is unregistered
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Web app is enabled through SetAppProperties
-- 3. Web app is registered and activated

-- Sequence:
-- 1. Web app is unregistered
--  a. SDL does send BC.UpdateAppList with Web app since it is still enabled
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')
local runner = require('user_modules/script_runner')

--[[ Required Shared libraries ]]
runner.testSettings.restrictions.sdlBuildOptions = {{webSocketServerSupport = {"ON"}}}

--[[ Local Variables ]]
  local appProp = {
    nicknames = { "Test Application" },
    policyAppID = "0000001",
    enabled = true,
    authToken = "ABCD12345",
    transportType = "WS",
    hybridAppPreference = "CLOUD"
  }

--[[ Local Functions ]]
local function setAppProperties()

  common.checkUpdateAppList(appProp.policyAppID, 1, 1)
  common.setAppProperties(appProp)
end

local function unRegisterApp()
  common.checkUpdateAppList(appProp.policyAppID, 1, 1)
  common.unRegisterApp()
end

local function registerApp()
  common.registerAppWOPTU()
  common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList")
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties enabled=true", setAppProperties)
common.Step("Register App", registerApp)
common.Step("Activate App", common.activateApp)
common.Step("Unregister App", unRegisterApp)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
