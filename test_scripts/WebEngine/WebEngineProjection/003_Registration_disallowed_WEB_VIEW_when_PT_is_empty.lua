---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that App will be rejected with HMI type WEB_VIEW
-- when mobile application has no policy record in local policy table
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
--
-- Sequence:
-- 1. Application1 tries to register with WEB_VIEW appHMIType
--  a. SDL rejects registration of application (resultCode: "DISALLOWED", success: false)
-- 2. Application2 tries to register with NAVIGATION appHMIType
--  a. SDL successfully registers application (resultCode: "SUCCESS", success: true)
--  b. SDL creates policy table snapshot and start policy table update
-- 3. Check absence of permissions for rejected application in LPT
--  a. Permission for rejected Application1 is absent in LPT
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultMobileAdapterType = "WS"

-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local webEngineDevice = 1
local appHMITypeWebView = { "WEB_VIEW" }
local appHMITypeNavigation = { "NAVIGATION" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMITypeWebView
config.application2.registerAppInterfaceParams.appHMIType = appHMITypeNavigation

--[[ Local Functions ]]
local function checkAbsenceOfPermissions()
  local ptsTable = common.ptsTable()
  if not ptsTable then
    common.failTestStep("Policy table snapshot was not created")
  elseif ptsTable.policy_table.app_policies[common.getParams(appSessionId1).fullAppID] ~= nil then
    common.failTestStep("Permission for rejected application is present in LPT")
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start)

common.Title("Test")
common.Step("Register App1 with WEB_VIEW appHmiType", common.expectRegistrationDisallowed, { appSessionId1 })
common.Step("Connect WebEngine device", common.connectWebEngine, { webEngineDevice, "WS" })
common.Step("Register App2 with NAVIGATION appHmiType", common.registerApp, { appSessionId2 })
common.Step("Check absence of permissions for rejected application in LPT", checkAbsenceOfPermissions)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
