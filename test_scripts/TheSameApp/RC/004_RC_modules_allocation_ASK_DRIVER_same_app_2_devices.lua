---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: RC modules allocation in ASK_DRIVER mode for the same applications that are registered
--  on two mobile devices
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile №1 and №2 are connected to SDL and are consented
-- 3)RC Application (HMI type = REMOTE_CONTROL) App1 is registered on Mobile №1 and Mobile №2
--   (two copies of one application)
--   App1 from Mobile №1 has hmiAppId_1 on HMI, App1 from Mobile №2 has hmiAppId_2 on HMI
-- 4)Remote control settings are: allowed:true, mode: ASK_DRIVER
-- 5)RC module RADIO allocated to App1 on Mobile №1
--   RC module CLIMATE allocated to App1 on Mobile №2
--   RC module LIGHT is free
--
-- Steps:
-- 1)Application App1 from Mobile №2 activates and sends to SDL valid SetInteriorVehicleData (module: RADIO)
--    RPC request to reallocate RADIO module
--    Driver rejects consent.
--    HMI sends response RC.GetInteriorVehicleDataConsent (false)
--   Check:
--    SDL sends RC.GetInteriorVehicleData (RADIO, hmiAppId_2) to HMI
--    SDL sends SetInteriorVehicleData(resultCode = REJECTED) response to App1 on Mobile №2
--    SDL does not send OnRCStatus notification to App1 on Mobile №1
--    SDL does not send OnRCStatus notification to App1 on Mobile №2
--    SDL does not send RC.OnRCStatus notification to HMI
--    SDL does not send RC.OnRCStatus notification to HMI
-- 2)Application App1 from Mobile №1 activates and sends to SDL valid SetInteriorVehicleData (module: CLIMATE)
--    RPC request to reallocate CLIMATE module
--    Driver accepts consent.
--    HMI sends response RC.GetInteriorVehicleDataConsent (true)
--   Check:
--    SDL sends RC.GetInteriorVehicleData (CLIMATE, hmiAppId_1) to HMI
--    SDL sends SetInteriorVehicleData(resultCode = SUCCESS) response to App1 on Mobile №1
--    SDL sends OnRCStatus(allocatedModules:(RADIO, CLIMATE), freeModules: (LIGHT)) notification to App1 on Mobile №1
--    SDL sends OnRCStatus(allocatedModules:(), freeModules: (LIGHT)) notification to App1 on Mobile №2
--    SDL sends RC.OnRCStatus(appId: hmiAppId_1, allocatedModules:(RADIO, CLIMATE), freeModules: (LIGHT)) notification
--    to HMI
--    SDL sends RC.OnRCStatus(appId: hmiAppId_2, allocatedModules:(), freeModules: (LIGHT)) notification to HMI
-- 3)Application App1 from Mobile №2 activates and sends to SDL valid SetInteriorVehicleData (module: LIGHT)
--    RPC request to allocate LIGHT module
--   Check:
--    SDL sends SetInteriorVehicleData(resultCode = SUCCESS) response to App1 on Mobile №2
--    SDL sends OnRCStatus(allocatedModules:(RADIO, CLIMATE), freeModules: ()) notification to App1 on Mobile №1
--    SDL sends OnRCStatus(allocatedModules:(LIGHT), freeModules: ()) notification to App1 on Mobile №2
--    SDL sends RC.OnRCStatus(appId: hmiAppId_1, allocatedModules:(RADIO, CLIMATE), freeModules: ()) notification to HMI
--    SDL sends RC.OnRCStatus(appId: hmiAppId_2, allocatedModules:(LIGHT), freeModules: ()) notification to HMI
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
  }
}

local rcAppIds = { 1, 2 }
local hmiCapabilities = common.buildHmiRcCapabilities({ CLIMATE = "Default", LIGHT = "Default", RADIO = "Default" })
local rcCapabilities = common.getRcCapabilities(hmiCapabilities)

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table
  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  local policyAppParams = common.cloneTable(pt.app_policies["default"])
  policyAppParams.AppHMIType = appParams[1].appHMIType
  policyAppParams.moduleType = { "RADIO", "CLIMATE", "LIGHT" }
  policyAppParams.groups = { "Base-4", "RemoteControl" }

  pt.app_policies[appParams[1].fullAppID] = policyAppParams
end

local function rejectedModuleApp1Dev2()
  common.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  common.mobile.getSession(1):ExpectNotification("OnRCStatus"):Times(0)
  common.mobile.getSession(2):ExpectNotification("OnRCStatus"):Times(0)
  common.rpcRejectWithConsent(2, "RADIO")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI with CLIMATE, LIGHT and RADIO RC modules", common.startWithRC, { hmiCapabilities })
runner.Step("Set AccessMode ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})
runner.Step("Activate App1 from Device 1", common.activateApp, {1})
runner.Step("App1 on Device 1 successfully allocates module RADIO", common.allocateModuleToApp, {1, "RADIO", rcAppIds, rcCapabilities})
runner.Step("Activate App1 from Device 2", common.activateApp, {2})
runner.Step("App1 on Device 2 successfully allocates module CLIMATE", common.allocateModuleToApp, {2, "CLIMATE", rcAppIds, rcCapabilities})

runner.Title("Test")
runner.Step("App1 on Device 2 rejected by driver to allocate module RADIO", rejectedModuleApp1Dev2)

runner.Step("Activate App1 from Device 1", common.activateApp, {1})
runner.Step("App1 on Device 1 approved by driver to allocate module CLIMATE", common.allocateModuleToAppWithConsent,
{ 1, "CLIMATE", rcAppIds, rcCapabilities })

runner.Step("Activate App1 from Device 2", common.activateApp, {2})
runner.Step("App1 on Device 2 successfully allocates module LIGHT", common.allocateModuleToApp,
{ 2, "LIGHT", rcAppIds, rcCapabilities })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
