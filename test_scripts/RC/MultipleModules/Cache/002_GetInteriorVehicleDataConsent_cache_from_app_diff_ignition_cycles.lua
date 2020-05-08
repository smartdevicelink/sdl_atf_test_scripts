---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that driver consent for reallocation of RC modules via GetInteriorVehicleDataConsent RPC
--  is cached and can be used across multiple ignition cycles
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules <X01> and <X02> (allowMultipleAccess: true) of each type to SDL
-- 3) Mobile is connected to SDL
-- 4) App1 (appHMIType: ["REMOTE_CONTROL"]) is registered from Mobile
-- 5) HMI level of App1 is FULL
-- 6) App1 from Mobile1 receives driver consents for reallocation of RC modules via GetInteriorVehicleDataConsent RPC
--    (driver allowed one of modules <X01> and disallow another <X02> for each type of modules)
--
-- Steps:
-- 1) Perform ignition off and ignition on (new ignition cycle started)
--    Set RC access mode to ASK_DRIVER
--    Reregister App1 and register and activate App2
--    Set user location of App1 and App2 within service area of modules <X01> and <X02>
--    Allocate modules <X01> and <X02> of each of module types to App2
--    Activate App1
--    Try to reallocate disallowed module <X02> without of asking driver to App1
--     via SetInteriorVehicleData RPC sequentially
--   Check:
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL rejects allocation of module <X02> to App1
--     and does not send OnRCStatus notifications to HMI and Apps
--    SDL responds on SetInteriorVehicleData RPC with resultCode: REJECTED
-- 2) Try to reallocate allowed module <X01> without of asking driver to App1
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
runner.Step("Enable RC and set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2", common.setUserLocation, { 2, appLocation[2] })

for moduleType, consentArray in pairs(testModules) do
  for moduleId in pairs(consentArray) do
    runner.Step("Allocate module [" .. moduleType .. ":" .. moduleId .. "] to App2",
      common.rpcSuccess, { moduleType, moduleId, 2, "SetInteriorVehicleData" })
  end
end

runner.Step("Activate App1", common.activateApp, { 1 })
for moduleType, consentArray in pairs(testModules) do
  runner.Step("Allow/disallow " .. moduleType .. " modules reallocation to App1",
    common.driverConsentForReallocationToApp, { 1, moduleType, consentArray, { 1 } })
end
runner.Step("Unregister App1", common.unRegisterApp, { 1 })
runner.Step("Unregister App2", common.unRegisterApp, { 2 })

runner.Title("Test")
runner.Step("Ignition off", common.ignitionOff)
runner.Step("Start SDL and HMI 2nd cycle", common.start, { rcCapabilities })
runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register App1 again", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2", common.setUserLocation, { 2, appLocation[2] })

for moduleType, consentArray in pairs(testModules) do
  for moduleId in pairs(consentArray) do
    runner.Step("Allocate module [" .. moduleType .. ":" .. moduleId .. "] to App2",
      common.rpcSuccess, { moduleType, moduleId, 2, "SetInteriorVehicleData" })
  end
end

runner.Step("Activate App1", common.activateApp, { 1 })
for moduleType, consentArray in pairs(testModules) do
  for moduleId, isAllowed in pairs(consentArray) do
    runner.Step("Try to reallocate " .. tostring(isAllowed and "allowed" or "disallowed")
        .. " module [" .. moduleType .. ":" .. moduleId .. "] to App1",
      common.getAllocationFunction(isAllowed, false),
      { 1, moduleType, moduleId, nil, rcAppIds })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
