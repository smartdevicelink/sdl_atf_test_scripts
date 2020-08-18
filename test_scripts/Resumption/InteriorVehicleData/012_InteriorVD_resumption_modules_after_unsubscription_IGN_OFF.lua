---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data after IGN_OFF in case of processing unsubscription
--  before resumption
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to module_1, module_2 and module_3
-- 4. App is unsubscribed from module_2 and module_3
-- 5. App receives updated hashId after unsubscription
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. App starts registration with actual hashId after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe=true, module_1) to HMI during resumption data
-- - b. respond RAI(SUCCESS) to mobile app
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribed = true
local withoutModuleId = nil
local seatModuleId = common.getModuleId("SEAT", 2)
local isUnsubscribed = false
local appSessionId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local defaultModuleNumber = 1
  local moduleType = "RADIO"
  local modulesCount = 1
  local expectedModules = {
    {
      moduleType = moduleType,
      subscribe = true,
      moduleId = common.getModuleId(moduleType, defaultModuleNumber)
    }
  }
  common.checkResumptionData(modulesCount, expectedModules, true)
  common.wait(1000)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Add interiorVD subscription for RADIO", common.GetInteriorVehicleData,
  { "RADIO", withoutModuleId, isSubscribed })
common.Step("Add interiorVD subscription for CLIMATE", common.GetInteriorVehicleData,
  { "CLIMATE", withoutModuleId, isSubscribed })
common.Step("Add interiorVD subscription for SEAT", common.GetInteriorVehicleData,
  { "SEAT", seatModuleId, isSubscribed })
common.Step("Unsubscribe from CLIMATE", common.GetInteriorVehicleData, { "CLIMATE", withoutModuleId, isUnsubscribed })
common.Step("Unsubscribe from SEAT", common.GetInteriorVehicleData, { "SEAT", seatModuleId, isUnsubscribed })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Reregister App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, common.resumptionFullHMILevel })
common.Step("Check subscription with OnInteriorVD for RADIO", common.onInteriorVD,
  { "RADIO", withoutModuleId, isSubscribed })
common.Step("Check subscription with OnInteriorVD for CLIMATE", common.onInteriorVD,
  { "CLIMATE", withoutModuleId, isUnsubscribed })
common.Step("Check subscription with OnInteriorVD for SEAT", common.onInteriorVD,
  { "SEAT", seatModuleId, isUnsubscribed })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
