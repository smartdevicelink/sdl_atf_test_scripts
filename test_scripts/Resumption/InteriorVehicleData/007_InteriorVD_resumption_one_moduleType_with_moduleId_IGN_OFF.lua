---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data after IGN_OFF
--  in case app was subscribed to one module with moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to moduleType_1 via GetInteriorVehicleData(moduleType_1, moduleId)
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. App starts registration with actual hashId after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe=true, moduleType_1, moduleId) to HMI during resumption data
-- 3. HMI sends successful RC.GetInteriorVehicleData(moduleType_1, isSubscribed = true) response to SDL
-- SDL does:
-- - a. respond RAI(success=true, result code = SUCCESS) to mobile app
-- - b. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleType = common.modules[1]
local moduleId = common.getModuleId(moduleType, 2)
local appSessionId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local modulesCount = 1
  local expectedModules = {
    {
      moduleType = moduleType,
      subscribe = true,
      moduleId = moduleId
    }
  }
  common.checkResumptionData(modulesCount, expectedModules, true)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Add interiorVD subscription", common.GetInteriorVehicleData,
  { moduleType, moduleId, common.IVDataSubscribeAction.subscribe })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, common.resumptionFullHMILevel })
common.Step("Check subscription with OnInteriorVD", common.onInteriorVD, { moduleType, moduleId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
