---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that user location set via SetGlobalProperties RPC
--  has no influence on data receiving RPC GetInteriorVehicleData and OnInteriorVehicleData notification
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) Mobile is connected to SDL
-- 3) App1 registered from Mobile
--    HMI level of App1 is FULL
-- 4) RC modules are free
--
-- Steps:
-- 1) Send SetGlobalProperties RPC with userLocation: <out of module serviceArea>
--     (moduleType: <moduleType>, moduleId: <moduleId>) from App1
--    HMI responds on RC.SetGlobalProperties request with SUCCESS
--   Check:
--    SDL sends RC.SetGlobalProperties request with userLocation: <out of module serviceArea> to HMI
--    SDL responds on SetGlobalProperties RPC with resultCode: SUCCESS
-- 2) Send GetInteriorVehicleData RPC with subscribe: true for one module of each RC module type sequentially
--     (moduleType: <moduleType>, moduleId: <moduleId>) from App1
--    HMI responds on RC.GetInteriorVehicleData request with isSubscribed: true for module
--     (moduleType: <moduleType>, moduleId: <moduleId>)
--   Check:
--    SDL responds on GetInteriorVehicleData RPC with resultCode: SUCCESS
-- 3) Send OnInteriorVehicleData notification for one module of each RC module type sequentially
--     (moduleType: <moduleType>, moduleId: <moduleId>) from HMI
--   Check:
--    SDL resends OnInteriorVehicleData notification to App1 with (moduleType: <moduleType>, moduleId: <moduleId>)
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.FRONT_PASSENGER
}

local testServiceArea = common.grid.BACK_RIGHT_PASSENGER

local rcAppIds = { 1 }

local rcCapabilities = common.initHmiRcCapabilitiesConsent(testServiceArea)
local testModulesArray = common.buildTestModulesArrayFirst(rcCapabilities)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("Send user location of App1 (Front Passenger)", common.setUserLocation, { 1, appLocation[1] })
for _, testModule in ipairs(testModulesArray) do
  runner.Step("Get interior vehicle data and subscribe to module ["
      .. testModule.moduleType .. ":" .. testModule.moduleId .. "] on App1",
    common.subscribeToModule, { testModule.moduleType, testModule.moduleId, 1, false })
  runner.Step("Receive data change notification for module ["
      .. testModule.moduleType .. ":" .. testModule.moduleId .. "] on App1",
    common.isSubscribed, { testModule.moduleType, testModule.moduleId, 1, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
