---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check allocation/reallocation of RC module to mobile application in case:
--  - RC module has allowMultipleAccess: true and serviceArea is defined
--  - RC access mode set from HMI: ASK_DRIVER
--  - application sent userLocation which is out of the serviceArea but it is driver location
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with module to SDL (moduleType: <moduleType>, moduleId: <moduleId>)
-- 3) Mobile is connected to SDL
-- 4) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered from Mobile
-- 5) App1 and App2 sent userLocation which is out of serviceArea of module but in Driver position
--    through SetGlobalProperties RPC
-- 6) HMI level of App1 is BACKGROUND;
--    HMI level of App2 is FULL
-- 7) RC module (moduleType: <moduleType>, moduleId: <moduleId>) is free
--
-- Steps:
-- 1) Allocate free module (moduleType: <moduleType>, moduleId: <moduleId>) to App2 via SetInteriorVehicleData RPC
--   Check:
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL allocates module (moduleType: <moduleType>, moduleId: <moduleId>) to App2
--      and sends appropriate OnRCStatus notifications
-- 2) Activate App1 and try to reallocate module (moduleType: <moduleType>, moduleId: <moduleId>)
--      to App1 via SetInteriorVehicleData RPC
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: true for module
--      (moduleType: <moduleType>, moduleId: <moduleId>)
--   Check:
--    SDL sends GetInteriorVehicleDataConsent RPC to HMI with module (moduleType: <moduleType>, moduleId: <moduleId>)
--    SDL allocates module (moduleType: <moduleType>, moduleId: <moduleId>) to App1
--      and sends appropriate OnRCStatus notifications
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
-- 3) Activate App2 and try to reallocate module (moduleType: <moduleType>, moduleId: <moduleId>)
--      to App2 via SetInteriorVehicleData RPC
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: false for module
--      (moduleType: <moduleType>, moduleId: <moduleId>)
--   Check:
--    SDL sends GetInteriorVehicleDataConsent RPC to HMI with module (moduleType: <moduleType>, moduleId: <moduleId>)
--    SDL responds on SetInteriorVehicleData RPC with resultCode: REJECTED
--    SDL does not allocate module (moduleType: <moduleType>, moduleId: <moduleId>) to App1
--      and does not send OnRCStatus notifications
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.DRIVER,
  [2] = common.grid.DRIVER
}

local rcAppIds = { 1, 2 }

local testModuleInfo = {
  serviceArea = common.grid.FRONT_PASSENGER,
  allowMultipleAccess = true
}

local rcCapabilities = common.initHmiRcCapabilitiesAllocation(testModuleInfo)
local testModules = common.buildTestModulesArray()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: AUTO_DENY", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Driver)", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2 (Driver)", common.setUserLocation, { 2, appLocation[2] })

runner.Title("Test")
for _, testModule in ipairs(testModules) do
  runner.Step("Allocate free module [".. testModule.moduleType .. ":" .. testModule.moduleId .. "] to App2",
      common.allocateModuleWithoutConsent, { 2, testModule.moduleType, testModule.moduleId, nil, rcAppIds })
end

runner.Step("Activate App1", common.activateApp, { 1 })
for _, testModule in ipairs(testModules) do
  runner.Step("Reallocate module [".. testModule.moduleType .. ":" .. testModule.moduleId
        .. "] to App1 after positive driver consent",
      common.allocateModuleWithConsent, { 1, testModule.moduleType, testModule.moduleId, nil, rcAppIds })
end

runner.Step("Activate App2", common.activateApp, { 2 })
for _, testModule in ipairs(testModules) do
  runner.Step("Reject reallocation of module [".. testModule.moduleType .. ":" .. testModule.moduleId
        .. "] to App2 after negative driver consent",
      common.rejectedAllocationOfModuleWithConsent, { 2, testModule.moduleType, testModule.moduleId, nil, rcAppIds })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
