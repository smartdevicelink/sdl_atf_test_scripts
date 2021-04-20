---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that driver consent for reallocation of RC modules via GetInteriorVehicleDataConsent RPC
--  is cached and can be used within one ignition cycle
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules <X01> and <X02> (allowMultipleAccess: true) of each type to SDL
-- 3) RC access mode set from HMI: ASK_DRIVER
-- 4) Mobile is connected to SDL
-- 5) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered from Mobile
-- 6) HMI level of App1 is BACKGROUND
--    HMI level of App2 is FULL
-- 7) User location of App1 and App2 are within of serviceArea of modules <X01> and <X02>
-- 8) RC modules <X01> and <X02> are allocated to App2
--
-- Steps:
-- 1) Try to reallocate module <X02> with negavive driver consent to App1
--     via SetInteriorVehicleData RPC
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: false for module <X02>
--   Check:
--    SDL sends GetInteriorVehicleDataConsent RPC to HMI with module <X02>
--    SDL does not allocate module <X02> to App1 and does not send OnRCStatus notifications
--    SDL responds on SetInteriorVehicleData RPC with resultCode: REJECTED
-- 2) Try to reallocate module <X01> with positive driver consent to App1
--     via SetInteriorVehicleData RPC
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: true for module <X01>
--   Check:
--    SDL sends GetInteriorVehicleDataConsent RPC to HMI with module <X01>
--    SDL allocates module <X01> to App1 and sends appropriate OnRCStatus notifications
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
-- 3) Unregister App1 (modules <X01> and <X02> become free)
--    Activate App2 and allocate modules <X01> and <X02> of each type of modules to App2
--    Reregister and activate App1
--    Set user location of App1 within service area of modules <X01> and <X02>
--    Try to reallocate disallowed module <X02> without of asking driver to App1
--     via SetInteriorVehicleData RPC sequentially
--   Check:
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL rejects allocation of module <X02> to App1
--     and does not send OnRCStatus notifications to HMI and Apps
--    SDL responds on SetInteriorVehicleData RPC with resultCode: REJECTED
-- 4) Try to reallocate allowed module <X01> without of asking driver to App1
--     via SetInteriorVehicleData RPC sequentially
--   Check:
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL allocates module <X01> to App1
--     and sends appropriate OnRCStatus notifications to HMI and Apps
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.BACK_RIGHT_PASSENGER,
  [2] = common.grid.BACK_CENTER_PASSENGER
}

local testServiceArea = common.grid.BACK_SEATS

local rcAppIds = { 1, 2 }

local rcCapabilities = common.initHmiRcCapabilitiesMultiConsent(testServiceArea)
local testModules = common.buildTestModulesStruct(rcCapabilities)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2", common.setUserLocation, { 2, appLocation[2] })

for moduleType, consentArray in pairs(testModules) do
  for moduleId in pairs(consentArray) do
    runner.Step("Allocate free module [" .. moduleType .. ":" .. moduleId .. "] to App2",
      common.rpcSuccess, { moduleType, moduleId, 2, "SetInteriorVehicleData" })
  end
end

runner.Step("Activate App1", common.activateApp, { 1 })
for moduleType, consentArray in pairs(testModules) do
  for moduleId, isAllowed in pairs(consentArray) do
    runner.Step("Try to reallocate module [" .. moduleType .. ":" .. moduleId .. "] with "
        .. tostring(isAllowed and "allowed" or "disallowed") .. " driver consent to App1",
      common.getAllocationFunction(isAllowed, true),
      { 1, moduleType, moduleId, nil, rcAppIds })
  end
end

runner.Title("Test")
runner.Step("Unregister App1", common.unRegisterApp, { 1 })
runner.Step("Activate App2", common.activateApp, { 2 })

for moduleType, consentArray in pairs(testModules) do
  for moduleId in pairs(consentArray) do
    runner.Step("Allocate free module [" .. moduleType .. ":" .. moduleId .. "] to App2",
      common.rpcSuccess, { moduleType, moduleId, 2, "SetInteriorVehicleData" })
  end
end

runner.Step("Register App1 again", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1", common.setUserLocation, { 1, appLocation[1] })

for moduleType, consentArray in pairs(testModules) do
  for moduleId, isAllowed in pairs(consentArray) do
    runner.Step("Try to reallocate " .. tostring(isAllowed and "allowed" or "disallowed")
        .. " module [" .. moduleType .. ":" .. moduleId .. "] without asking of driver consent to App1",
      common.getAllocationFunction(isAllowed, false),
      { 1, moduleType, moduleId, nil, rcAppIds })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
