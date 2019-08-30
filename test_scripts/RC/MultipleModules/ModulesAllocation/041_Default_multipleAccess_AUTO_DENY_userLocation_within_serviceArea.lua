---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check allocation/reallocation of RC module to mobile application in case:
--  - RC module has 'allowMultipleAccess' parameter missing and 'serviceArea' defined
--  - RC access mode set from HMI: AUTO_DENY
--  - application sent userLocation which is within the serviceArea
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with module to SDL (moduleType: <moduleType>, moduleId: <moduleId>)
-- 3) Mobile is connected to SDL
-- 4) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered from Mobile
-- 5) App1 and App2 sent userLocation which is within the serviceArea of module through SetGlobalProperties RPC
-- 6) HMI level of App1 is BACKGROUND;
--    HMI level of App2 is FULL
-- 7) RC module (moduleType: <moduleType>, moduleId: <moduleId>) is free
--
-- Steps:
-- 1) Allocate free module (moduleType: <moduleType>, moduleId: <moduleId>) to App2 via SetInteriorVehicleData RPC
--   Check:
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
--    SDL allocates module (moduleType: <moduleType>, moduleId: <moduleId>) to App2
-- 			and sends appropriate OnRCStatus notifications
-- 2) Activate App1 and try to reallocate module (moduleType: <moduleType>, moduleId: <moduleId>)
--      to App1 via SetInteriorVehicleData RPC
--   Check:
--    SDL responds on SetInteriorVehicleData RPC with resultCode: IN_USE
--    SDL does not allocate module (moduleType: <moduleType>, moduleId: <moduleId>) to App1
--      and does not send OnRCStatus notifications
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.FRONT_PASSENGER,
  [2] = common.grid.FRONT_PASSENGER
}

local rcAppIds = { 1, 2 }

local testModuleInfo = {
  serviceArea = common.grid.FRONT_PASSENGER,
  allowMultipleAccess = common.MISSED
}

local rcCapabilities = common.initHmiRcCapabilitiesAllocation(testModuleInfo)
local testModules = common.buildTestModulesArray()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: AUTO_DENY", common.defineRAMode, { true, "AUTO_DENY" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Front passenger)", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2 (Front passenger)", common.setUserLocation, { 2, appLocation[2] })

runner.Title("Test")
for _, testModule in ipairs(testModules) do
  runner.Step("Allocate free module [".. testModule.moduleType .. ":" .. testModule.moduleId .. "] to App2",
      common.allocateModule, { 2, testModule.moduleType, testModule.moduleId, nil, rcAppIds })
end

runner.Step("Activate App1", common.activateApp, { 1 })
for _, testModule in ipairs(testModules) do
  runner.Step("Reject reallocation of module [".. testModule.moduleType .. ":" .. testModule.moduleId .. "] to App1",
      common.rejectedAllocationOfModule, { 1, testModule.moduleType, testModule.moduleId, nil, rcAppIds, "IN_USE" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
