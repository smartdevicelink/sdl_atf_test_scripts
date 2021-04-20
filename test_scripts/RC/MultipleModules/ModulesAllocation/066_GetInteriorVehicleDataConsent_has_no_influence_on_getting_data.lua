---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that driver consent for reallocation of RC modules via GetInteriorVehicleDataConsent RPC
--  has no influence on data receiving RPC GetInteriorVehicleData and OnInteriorVehicleData notification
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules of each type to SDL
-- 3) RC access mode set from HMI: ASK_DRIVER
-- 4) Mobile is connected to SDL
-- 5) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered from Mobile
-- 6) App2 is within serviceArea of modules, App1 is not
-- 7) HMI level of App1 is BACKGROUND;
--    HMI level of App2 is FULL
-- 8) RC modules are free
--
-- Steps:
-- 1) Allocate free modules (moduleType: <moduleType>, moduleId: <moduleId>) to App2 via SetInteriorVehicleData RPC
--   Check:
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL allocates modules (moduleType: <moduleType>, moduleId: <moduleId1>) to App2
--     and sends appropriate OnRCStatus notifications
-- 2) Activate App1 and send GetInteriorVehicleDataConsent RPC for one module of each RC module type sequentially
--     (moduleType: <moduleType>, moduleIds: [<moduleId>]) from App1
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: false for module
--     (moduleType: <moduleType>, allowed: [false])
--   Check:
--    SDL sends RC.GetInteriorVehicleDataConsent request to HMI with (moduleType: <moduleType>, moduleIds:[<moduleId>])
--    SDL responds on GetInteriorVehicleDataConsent RPC with resultCode:"SUCCESS", success:true
--    SDL does not send OnRCStatus notifications to HMI and Apps
-- 3) Send GetInteriorVehicleData RPC with subscribe: true for one module of each RC module type sequentially
--     (moduleType: <moduleType>, moduleId: <moduleId>) from App1
--    HMI responds on RC.GetInteriorVehicleData request with isSubscribed: true for module
--     (moduleType: <moduleType>, moduleId: <moduleId>)
--   Check:
--    SDL responds on GetInteriorVehicleData RPC with resultCode: SUCCESS
-- 4) Send OnInteriorVehicleData notification for one module of each RC module type sequentially
--     (moduleType: <moduleType>, moduleId: <moduleId>) from HMI
--   Check:
--    SDL resends OnInteriorVehicleData notification to App1 with (moduleType: <moduleType>, moduleId: <moduleId>)
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- --[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.FRONT_PASSENGER,
  [2] = common.grid.FRONT_PASSENGER
}

local testServiceArea = common.grid.FRONT_PASSENGER

local rcAppIds = { 1, 2 }

local rcCapabilities = common.initHmiRcCapabilitiesConsent(testServiceArea)
local testModulesArray = common.buildTestModulesArrayFirst(rcCapabilities)

-- --[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Front Passenger)", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2 (Back seat)", common.setUserLocation, { 2, appLocation[2] })

for _, testModule in ipairs(testModulesArray) do
  runner.Step("Allocate module [" .. testModule.moduleType .. ":" .. testModule.moduleId .. "] to App2",
      common.rpcSuccess, { testModule.moduleType, testModule.moduleId, 2, "SetInteriorVehicleData" })
end

runner.Title("Test")
runner.Step("Activate App1", common.activateApp, { 1 })
for _, testModule in ipairs(testModulesArray) do
  runner.Step("Disallow module [" .. testModule.moduleType .. ":" .. testModule.moduleId
      .. "] reallocation to App1",
    common.driverConsentForReallocationToApp,
    { 1, testModule.moduleType, { [testModule.moduleId] = false }, rcAppIds })
end

for _, testModule in ipairs(testModulesArray) do
  runner.Step("Get interior vehicle data and subscribe to module ["
      .. testModule.moduleType .. ":" .. testModule.moduleId .. "] on App1",
    common.subscribeToModule, { testModule.moduleType, testModule.moduleId, 1, false })
end

for _, testModule in ipairs(testModulesArray) do
  runner.Step("Receive data change notification for module ["
      .. testModule.moduleType .. ":" .. testModule.moduleId .. "] on App1",
    common.isSubscribed, { testModule.moduleType, testModule.moduleId, 1, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
