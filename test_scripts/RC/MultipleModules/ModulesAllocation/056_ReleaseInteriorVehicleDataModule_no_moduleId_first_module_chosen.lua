---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check that SDL chooses first moduleId from capabilities for releasing of RC module
--  in case ReleaseInteriorVehicleDataModule RPC request contains moduleType and does not contain moduleId
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules of each type to SDL:
--    Default (first in capabilities) modules are CLIMATE:b468c01c, RADIO:3b41cd63, SEAT:650765bb
-- 3) Mobile is connected to SDL
-- 4) App1 (appHMIType: ["REMOTE_CONTROL"]) is registered from Mobile
-- 5) RC modules:
--     CLIMATE:b468c01c, CLIMATE:2df6518c, RADIO:00bd6d93, SEAT:a42bf1e0 allocated to App1
--     RADIO:3b41cd63 allocated to App2
--     SEAT:650765bb is free
-- 6) HMI level of App1 is FULL; HMI level of App1 is BACKGROUND
--
-- Steps:
-- 1) Send ReleaseInteriorVehicleDataModule RPC with moduleType: SEAT without moduleId from App1 to release RC module
--   Check:
--    SDL responds on ReleaseInteriorVehicleDataModule RPC with resultCode:"IGNORED",
--    SDL does not releases any module and does not sends OnRCStatus notifications to HMI and App
-- 2) Send ReleaseInteriorVehicleDataModule RPC with moduleType: RADIO without moduleId from App1 to release RC module
--   Check:
--    SDL responds on ReleaseInteriorVehicleDataModule RPC with resultCode:"REJECTED",
--    SDL does not releases any module and does not sends OnRCStatus notifications to HMI and App
-- 3) Send ReleaseInteriorVehicleDataModule RPC with moduleType: CLIMATE without moduleId from App1 to release RC module
--   Check:
--    SDL responds on ReleaseInteriorVehicleDataModule RPC with resultCode:"SUCCESS",
--    SDL releases module CLIMATE:b468c01c and sends OnRCStatus notifications to HMI and App
--     with freeModules array which contains module CLIMATE:b468c01c
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.FRONT_PASSENGER
}

local moduleIdUpdates = {
  CLIMATE = { "b468c01c-9346-4331-bd4f-927ca97f0103", "2df6518c-ca8a-4e7c-840a-0eba5c028351" },
  RADIO = { "3b41cd63-d6b0-4e5e-b831-70e937326074", "00bd6d93-e093-4bf0-9784-281febe41bed" },
  SEAT = { "650765bb-2f89-4d68-a665-6267c80e6c62", "a42bf1e0-e02e-4462-912a-7d4230815f73" }
}

local function initHmiRcCapabilitiesForReleaseDefault(pAppLocation)
  local capabilities = common.getRcCapabilities()

  for updModuleType, updModuleIds in pairs(moduleIdUpdates) do
    local data = capabilities[updModuleType][1]
    local newModuleTypeCapabilities = { }
    for _, updModuleId in ipairs(updModuleIds) do
      local newModuleData = common.cloneTable(data)
      newModuleData.moduleInfo.moduleId = updModuleId
      newModuleData.moduleInfo.serviceArea = pAppLocation
      table.insert(newModuleTypeCapabilities, newModuleData)
    end
    capabilities[updModuleType] = newModuleTypeCapabilities
  end
  return capabilities
end

local rcAppIds = { 1, 2 }
local rcCapabilities = initHmiRcCapabilitiesForReleaseDefault(appLocation[1])
local testModulesAllocation = {
  [1] = {
    { moduleType = "CLIMATE", moduleId = moduleIdUpdates.CLIMATE[2] },
    { moduleType = "CLIMATE", moduleId = moduleIdUpdates.CLIMATE[1] },
    { moduleType = "RADIO", moduleId = moduleIdUpdates.RADIO[2] },
    { moduleType = "SEAT", moduleId = moduleIdUpdates.SEAT[2] }
  },
  [2] = {
    { moduleType = "RADIO", moduleId = moduleIdUpdates.RADIO[1] }
  }
}

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
runner.Step("Send user location of App1 (Front passenger seat)", common.setUserLocation, { 1, appLocation[1] })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("Send user location of App2 (Front passenger seat)", common.setUserLocation, { 2, appLocation[1] })
for appId in ipairs(testModulesAllocation) do
  runner.Step("Activate App " .. appId, common.activateApp, { appId })
  for _, testModule in ipairs(testModulesAllocation[appId]) do
    runner.Step("Allocate module [" .. testModule.moduleType .. ":" .. testModule.moduleId .. "] to App ".. appId,
        common.allocateModule, { appId, testModule.moduleType, testModule.moduleId, nil, rcAppIds })
  end
end

runner.Title("Test")
runner.Step("Try to release default module SEAT", common.releaseModuleNoModuleId,
    { 1, "SEAT", moduleIdUpdates.SEAT[1], "IGNORED", "FREE_MODULE", rcAppIds })
runner.Step("Try to release default module RADIO", common.releaseModuleNoModuleId,
    { 1, "RADIO", moduleIdUpdates.RADIO[1], "REJECTED", "ALLOCATED_TO_ANOTHER_APP", rcAppIds })
runner.Step("Try to release default module CLIMATE", common.releaseModuleNoModuleId,
    { 1, "CLIMATE", moduleIdUpdates.CLIMATE[1], "SUCCESS", "SUCCESS", rcAppIds })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
