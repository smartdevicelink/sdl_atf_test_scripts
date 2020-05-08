---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Registration of two mobile applications from different devices having different appIDs and
-- matched appNames.
-- App_2 re-registers using one name from its "nickname" field,
-- App_2 re-registers using another name from its "nickname" field.
--
-- Preconditions:
-- 1) PT contains entity ( appID = 0000001,  nicknames = "Test Application", "Test Application 2" )
-- 1) PT contains entity ( appID = 00000022, nicknames = "Test Application", "Test Application 2", "Test Application 3")
-- 2) SDL and HMI are started
-- 3) Mobile №1 is registered with ( appID = 0000001,  appName = "Test Application 2" )
-- 4) Mobile №2 is registered with ( appID = 00000022, appName = "Test Application 2" )
--
-- Steps:
-- 1) Mobile №2 sends ChangeRegistration RPC request (appName = "Test Application") to SDL
--   Check:
--    SDL sends ChangeRegistration response( resultCode = SUCCESS ) to Mobile №1
-- 2) Mobile №2 sends ChangeRegistration request appName = "Test Application 3") to SDL
--   Check:
--    SDL sends ChangeRegistration response( resultCode = SUCCESS ) to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')
local json = require("modules/json")
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "Test Application 2", appID = "0001",  fullAppID = "0000001" },
  [2] = { appName = "Test Application 2", appID = "00022", fullAppID = "00000022" }
}

local changeRegParams = {
  [1] = {
    language ="EN-US",
    hmiDisplayLanguage ="EN-US",
    appName ="Test Application"
  },
  [2] = {
    language ="EN-US",
    hmiDisplayLanguage ="EN-US",
    appName ="Test Application 3"
  }
}

--[[ Local Functions ]]
local function setNickname(pt)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.app_policies["0000001"]  = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000001"].nicknames  = { "Test Application", "Test Application 2" }
  pt.policy_table.app_policies["00000022"] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["00000022"].nicknames = { "Test Application", "Test Application 2", "Test Application 3"}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update of the default PT", common.modifyPreloadedPt, {setNickname})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 2", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from device 2", common.registerAppEx, {2, appParams[2], 2})

runner.Title("Test")
runner.Step("Change registration of App2 from device 2", common.changeRegistrationPositive, {2, changeRegParams[1]})
runner.Step("Change registration of App2 from device 2", common.changeRegistrationPositive, {2, changeRegParams[2]})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
