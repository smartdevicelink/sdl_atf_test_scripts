---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: RC modules reallocation in AUTO_ALLOW mode for the same applications that are registered
--  on two mobile devices
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile №1 and №2 are connected to SDL and are consented
-- 3)RC Application (HMI type = REMOTE_CONTROL) App1 is registered on Mobile №1 and Mobile №2
--   (two copies of one application)
--   RC Application (HMI type = REMOTE_CONTROL) App2 is registered on Mobile №2
--   App1 from Mobile №1 has hmiAppId_1 on HMI, App1 from Mobile №2 has hmiAppId_2 on HMI,
--   App2 from Mobile №2 has hmiAppId_3
-- 4)Remote control settings are: allowed:true, mode: AUTO_ALLOW
-- 5)RC module RADIO allocated to App1 on Mobile №1
--   RC module CLIMATE allocated to App1 on Mobile №2
--   RC module LIGHT allocated to App2 on Mobile №2
--
-- Steps:
-- 1)Application App2 from Mobile №2 activates and sends to SDL valid SetInteriorVehicleData (module: RADIO)
--    RPC request to allocate RADIO module
--   Check:
--    SDL sends SetInteriorVehicleData(resultCode = SUCCESS) response to App2 on Mobile №2
--    SDL sends OnRCStatus(allocatedModules:(), freeModules: ()) notification to App1 on Mobile №1
--    SDL sends OnRCStatus(allocatedModules:(CLIMATE), freeModules: ()) notification to App1 on Mobile №2
--    SDL sends OnRCStatus(allocatedModules:(LIGHT, RADIO), freeModules: ()) notification to App2 on Mobile №2
--    SDL sends RC.OnRCStatus(appId: hmiAppId_1, allocatedModules:(), freeModules: ()) notification to HMI
--    SDL sends RC.OnRCStatus(appId: hmiAppId_2, allocatedModules:(CLIMATE), freeModules: ()) notification to HMI
--    SDL sends RC.OnRCStatus(appId: hmiAppId_3, allocatedModules:(LIGHT, RADIO), freeModules: ()) notification to HMI
-- 2)Application App1 from Mobile №1 activates and sends to SDL valid SetInteriorVehicleData (module: CLIMATE)
--    RPC request to allocate CLIMATE module
--   Check:
--    SDL sends SetInteriorVehicleData(resultCode = SUCCESS) response to App1 on Mobile №1
--    SDL sends OnRCStatus(allocatedModules:(CLIMATE), freeModules: ()) notification to App1 on Mobile №1
--    SDL sends OnRCStatus(allocatedModules:(), freeModules: ()) notification to App1 on Mobile №2
--    SDL sends OnRCStatus(allocatedModules:(LIGHT, RADIO), freeModules: ()) notification to App2 on Mobile №2
--    SDL sends RC.OnRCStatus(appId: hmiAppId_1, allocatedModules:(CLIMATE), freeModules: ()) notification to HMI
--    SDL sends RC.OnRCStatus(appId: hmiAppId_2, allocatedModules:(), freeModules: ()) notification to HMI
--    SDL sends RC.OnRCStatus(appId: hmiAppId_3, allocatedModules:(LIGHT, RADIO), freeModules: ()) notification to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = {
    appName = "Test Application",
    isMediaApplication = false,
    appHMIType = { "REMOTE_CONTROL" },
    appID = "0001",
    fullAppID = "0000001",
  },
  [2] = {
    appName = "Test Application2",
    isMediaApplication = false,
    appHMIType = { "REMOTE_CONTROL" },
    appID = "0021",
    fullAppID = "0000021",
  },
}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table
  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  local policyAppParams = common.cloneTable(pt.app_policies["default"])
  policyAppParams.AppHMIType = appParams[1].appHMIType
  policyAppParams.moduleType = { "RADIO", "CLIMATE", "LIGHT" }
  policyAppParams.groups = { "Base-4", "RemoteControl" }

  pt.app_policies[appParams[1].fullAppID] = policyAppParams
  pt.app_policies[appParams[2].fullAppID] = common.cloneTable(policyAppParams)
  pt.app_policies[appParams[2].fullAppID].AppHMIType = appParams[2].appHMIType

end

local rcAppIds = { 1, 2, 3 }
local hmiCapabilities = common.buildHmiRcCapabilities({ CLIMATE = "Default", LIGHT = "Default", RADIO = "Default" })
local rcCapabilities = common.getRcCapabilities(hmiCapabilities)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI with CLIMATE, LIGHT and RADIO RC modules", common.startWithRC, { hmiCapabilities })
runner.Step("Set AccessMode AUTO_ALLOW", common.defineRAMode, { true, "AUTO_ALLOW" })
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})
runner.Step("Register App2 from device 2", common.registerAppEx, {3, appParams[2], 2})
runner.Step("Activate App1 from Device 1", common.activateApp, {1})
runner.Step("App1 on Device 1 successfully allocates module RADIO", common.allocateModuleToApp, {1, "RADIO", rcAppIds, rcCapabilities })
runner.Step("Activate App1 from Device 2", common.activateApp, {2})
runner.Step("App1 on Device 2 successfully allocates module CLIMATE", common.allocateModuleToApp, {2, "CLIMATE", rcAppIds, rcCapabilities })
runner.Step("Activate App2 from Device 2", common.activateApp, {3})
runner.Step("App2 on Device 2 successfully allocates module LIGHT", common.allocateModuleToApp, {3, "LIGHT", rcAppIds, rcCapabilities })

runner.Title("Test")
runner.Step("App2 on Device 2 successfully reallocates module RADIO from App1 on Device 1", common.allocateModuleToApp,
    { 3, "RADIO", rcAppIds, rcCapabilities })

runner.Step("Activate App1 from Device 1", common.activateApp, {1})
runner.Step("App1 on Device 1 successfully reallocates module CLIMATE from App1 on Device 2", common.allocateModuleToApp,
    { 1, "CLIMATE", rcAppIds, rcCapabilities })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
