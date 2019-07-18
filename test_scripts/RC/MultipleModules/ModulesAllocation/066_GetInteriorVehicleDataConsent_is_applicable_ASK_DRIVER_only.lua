---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that driver consent for reallocation of RC modules via GetInteriorVehicleDataConsent RPC
--  can be performed in any of RC access modes but its result is applicable in ASK_DRIVER mode only
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules of each type (allowMultipleAccess: true) to SDL
-- 3) RC access mode set from HMI: AUTO_ALLOW
-- 4) Mobile is connected to SDL
-- 5) App1 and App2 (appHMIType: ["REMOTE_CONTROL"]) are registered from Mobile
-- 6) App1 and App2 are within serviceArea of modules
-- 7) HMI level of App1 is BACKGROUND;
--    HMI level of App2 is FULL
-- 8) RC modules are free
--
-- Steps:
-- 1) Allocate free modules (moduleType: <moduleType>, moduleId: <moduleId1>)
--     and (moduleType: <moduleType>, moduleId: <moduleId2>) to App2 via SetInteriorVehicleData RPC
--   Check:
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL allocates modules (moduleType: <moduleType>, moduleId: <moduleId1>)
--     and (moduleType: <moduleType>, moduleId: <moduleId2>) to App2 and sends appropriate OnRCStatus notifications
-- 2) Activate App1 and send GetInteriorVehicleDataConsent RPC for one module of each RC module type consequentially
--     (moduleType: <moduleType>, moduleIds: [<moduleId1>]) from App1
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: false for module
--     (moduleType: <moduleType>, allowed: [false])
--   Check:
--    SDL sends RC.GetInteriorVehicleDataConsent request to HMI with (moduleType: <moduleType>, moduleIds:[<moduleId1>])
--    SDL responds on GetInteriorVehicleDataConsent RPC with resultCode:"SUCCESS", success:true
--    SDL does not send OnRCStatus notifications to HMI and Apps
-- 3) Set RC access mode to AUTO_DENY from HMI
--   Check:
--    SDL applies RC access mode
-- 4) Send GetInteriorVehicleDataConsent RPC for other module of each RC module type consequentially
--     (moduleType: <moduleType>, moduleIds: [<moduleId2>]) from App1
--    HMI responds on GetInteriorVehicleDataConsent request with allowed: true for module
--     (moduleType: <moduleType>, allowed: [true])
--   Check:
--    SDL sends RC.GetInteriorVehicleDataConsent request to HMI with (moduleType: <moduleType>, moduleIds:[<moduleId2>])
--    SDL responds on GetInteriorVehicleDataConsent RPC with resultCode:"SUCCESS", success:true
--    SDL does not send OnRCStatus notifications to HMI and Apps
-- 5) Try to reallocate allowed modules (moduleType: <moduleType>, moduleId: <moduleId1>)
--     to App1 via SetInteriorVehicleData RPC consequentially
--   Check:
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL rejects module reallocation (moduleType: <moduleType>, moduleId: <moduleId1>) to App1
--     and does not send OnRCStatus notifications to HMI and Apps
--    SDL responds on SetInteriorVehicleData RPC with resultCode: IN_USE
-- 6) Set RC access mode to ASK_DRIVER from HMI
--   Check:
--    SDL applies RC access mode
-- 7) Try to reallocate allowed modules (moduleType: <moduleType>, moduleId: <moduleId1>)
--     to App1 via SetInteriorVehicleData RPC consequentially
--   Check:
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL allocates module (moduleType: <moduleType>, moduleId: <moduleId1>) to App1
--     and sends appropriate OnRCStatus notifications to HMI and Apps
--    SDL responds on SetInteriorVehicleData RPC with resultCode: SUCCESS
-- 8) Try to reallocate disallowed modules (moduleType: <moduleType>, moduleId: <moduleId2>)
--     to App1 via SetInteriorVehicleData RPC consequentially
--   Check:
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL rejects module reallocation (moduleType: <moduleType>, moduleId: <moduleId2>) to App1
--     and does not send OnRCStatus notifications to HMI and Apps
--    SDL responds on SetInteriorVehicleData RPC with resultCode: REJECTED
-- 9) Set RC access mode to AUTO_ALLOW from HMI
--   Check:
--    SDL applies RC access mode
-- 10) Try to reallocate disallowed modules (moduleType: <moduleType>, moduleId: <moduleId2>)
--     to App1 via SetInteriorVehicleData RPC consequentially
--   Check:
--    SDL does not send GetInteriorVehicleDataConsent RPC to HMI
--    SDL allocates module (moduleType: <moduleType>, moduleId: <moduleId2>) to App1
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

--[[ Local Functions ]]
local function buildTestModulesStruct(pRcCapabilities)
  local excludedModuleTypes = {"BUTTONS", "HMI_SETTINGS", "LIGHT"}
  local modulesStuct = {}
  for moduleType, modules in pairs(pRcCapabilities) do
    if not common.isTableContains(excludedModuleTypes, moduleType) then
      modulesStuct[moduleType] = {}
      modulesStuct[moduleType].allowed = {}
      modulesStuct[moduleType].disallowed = {}
      local isAllowed = true
      for _, rcModuleCapabilities in ipairs(modules) do
        local collectionName = isAllowed and "allowed" or "disallowed"
        modulesStuct[moduleType][collectionName][rcModuleCapabilities.moduleInfo.moduleId] = isAllowed
        isAllowed = not isAllowed
      end
    elseif moduleType ~= "BUTTONS" then
      modulesStuct[moduleType] = {}
      modulesStuct[moduleType].allowed = {}
      modulesStuct[moduleType].disallowed = {}
      local isAllowed = moduleType == "HMI_SETTINGS"
      local collectionName = isAllowed and "allowed" or "disallowed"
      modulesStuct[moduleType][collectionName][modules.moduleInfo.moduleId] = isAllowed
    end
  end
  return modulesStuct
end

local rcCapabilities = common.initHmiRcCapabilitiesMultiConsent(testServiceArea)
local testModules = buildTestModulesStruct(rcCapabilities)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: AUTO_ALLOW", common.defineRAMode, { true, "AUTO_ALLOW" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Back Seat)", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2 (Back seat)", common.setUserLocation, { 2, appLocation[2] })

for moduleType, consents in pairs(testModules) do
  for _, consentArray in pairs(consents) do
    for moduleId in pairs(consentArray) do
      runner.Step("Allocate module [" .. moduleType .. ":" .. moduleId .. "] to App2",
        common.rpcSuccess, { moduleType, moduleId, 2, "SetInteriorVehicleData" })
    end
  end
end

runner.Title("Test")
runner.Title("RA mode: AUTO_ALLOW")
runner.Step("Activate App1", common.activateApp, { 1 })
for moduleType, consents in pairs(testModules) do
  if next(consents.disallowed) then
    runner.Step("Disallow " .. moduleType .. " modules reallocation to App1 without asking driver",
      common.driverConsentForReallocationToApp, { 1, moduleType, consents.disallowed, rcAppIds })
  end
end

runner.Step("Set RA mode: AUTO_DENY", common.defineRAMode, { true, "AUTO_DENY" })
runner.Title("RA mode: AUTO_DENY")
for moduleType, consents in pairs(testModules) do
  if next(consents.allowed) then
    runner.Step("Allow " .. moduleType .. " modules reallocation to App1 without asking driver",
      common.driverConsentForReallocationToApp, { 1, moduleType, consents.allowed, rcAppIds })
  end
end

for moduleType, consents in pairs(testModules) do
  for moduleId in pairs(consents.allowed) do
    runner.Step("Try to reallocate allowed module [" .. moduleType .. ":" .. moduleId .. "] to App1",
      common.rejectedAllocationOfModuleWithoutConsent, { 1, moduleType, moduleId, nil, rcAppIds, "IN_USE"})
  end
end

runner.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Title("RA mode: ASK_DRIVER")
for moduleType, consents in pairs(testModules) do
  for moduleId in pairs(consents.allowed) do
    runner.Step("Reallocate allowed module [" .. moduleType .. ":" .. moduleId .. "] to App1",
      common.allocateModuleWithoutConsent, { 1, moduleType, moduleId, nil, rcAppIds })
  end
end

for moduleType, consents in pairs(testModules) do
  for moduleId in pairs(consents.disallowed) do
    runner.Step("Try to reallocate disallowed module [" .. moduleType .. ":" .. moduleId .. "] to App1",
      common.rejectedAllocationOfModuleWithoutConsent, { 1, moduleType, moduleId, nil, rcAppIds })
  end
end

runner.Step("Set RA mode: AUTO_ALLOW", common.defineRAMode, { true, "AUTO_ALLOW" })
for moduleType, consents in pairs(testModules) do
  for moduleId in pairs(consents.disallowed) do
    runner.Step("Reallocate disallowed module [" .. moduleType .. ":" .. moduleId .. "] to App1",
      common.allocateModuleWithoutConsent, { 1, moduleType, moduleId, nil, rcAppIds })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
