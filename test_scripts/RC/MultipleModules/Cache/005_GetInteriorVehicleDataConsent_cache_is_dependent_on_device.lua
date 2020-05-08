---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that driver consent for reallocation of RC modules via GetInteriorVehicleDataConsent RPC
--  is cached and has dependency on mobile device
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules <X01> and <X02> (allowMultipleAccess: true) of each type to SDL
-- 3) Mobile1 and Mobile2 are connected to SDL
-- 4) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered on Mobile1
-- 5) HMI level of App1 is BACKGROUND
--    HMI level of App2 is FULL
-- 6) User location of App1 and App2 are within of serviceArea of modules <X01> and <X02>
-- 7) RC modules <X01> and <X02> are allocated to App2
-- 8) App1 from Mobile1 receives driver consents for reallocation of RC modules via GetInteriorVehicleDataConsent RPC
--    (driver allowed one of modules <X01> and disallow another <X02> for each type of modules)
--
-- Steps:
-- 1) Unregister App1 on Mobile1
--    Register and activate App1 on Mobile2
--    Set user location App1 within service area of modules <X01> and <X02>
--    Try to reallocate module <X02> with positive driver consent to App1
--     via SetInteriorVehicleData RPC
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: true for module <X02>
--   Check:
--    SDL sends GetInteriorVehicleDataConsent RPC to HMI with module <X02>
--    SDL allocates module <X02> to App1 and sends appropriate OnRCStatus notifications
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
-- 2) Try to reallocate module <X01> with positive driver consent to App1
--     via SetInteriorVehicleData RPC
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: true for module <X01>
--   Check:
--    SDL sends GetInteriorVehicleDataConsent RPC to HMI with module <X01>
--    SDL allocates module <X01> to App1 and sends appropriate OnRCStatus notifications
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Conditions to scik test ]]
if config.defaultMobileAdapterType == "WS" or config.defaultMobileAdapterType == "WSS" then
  runner.skipTest("Test is not applicable for WS/WSS connection")
end

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- --[[ Local Variables ]]
local anotherDeviceParams = { host = "192.168.100.199", port = config.mobilePort }

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
runner.Step("Start SDL, HMI, connect Mobile1", common.start, { rcCapabilities })
runner.Step("Connect another mobile device (Mobile2)", common.connectMobDevice, { 2, anotherDeviceParams})
runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register App1 on Mobile1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2 on Mobile1", common.registerAppWOPTU, { 2 })
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
    common.driverConsentForReallocationToApp, { 1, moduleType, consentArray, rcAppIds })
end

runner.Title("Test")
runner.Step("Unregister App1", common.unRegisterApp, { 1 })
runner.Step("Register App1 on Mobile2", common.registerAppWOPTU, { 1, 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1", common.setUserLocation, { 1, appLocation[1] })

for moduleType, consentArray in pairs(testModules) do
  for moduleId in pairs(consentArray) do
    runner.Step("Reallocate module [" .. moduleType .. ":" .. moduleId .. "] to App1 asking driver to consent",
      common.allocateModuleWithConsent, { 1, moduleType, moduleId, nil, rcAppIds})
  end
end

runner.Title("Postconditions")
runner.Step("Remove another mobile device", common.deleteMobDevice, { 2 })
runner.Step("Stop SDL", common.postconditions)
