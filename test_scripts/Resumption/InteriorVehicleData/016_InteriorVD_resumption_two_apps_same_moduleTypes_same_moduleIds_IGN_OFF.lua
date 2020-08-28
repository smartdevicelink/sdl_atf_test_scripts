---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data for two apps after IGN_OFF in case apps are subscribed to
--  the same moduleTypes with the same moduleIds
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app1 and app2 with REMOTE_CONTROL hmi type are registered and activated
-- 3. App1 is subscribed to moduleType_1
-- 4. App2 is subscribed to moduleType_1
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. Apps start registration with actual hashIds after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(moduleType_1) to HMI during resumption data
-- 3. HMI sends successful RC.GetInteriorVehicleData(moduleType_1, isSubscribed = true) response to SDL
-- SDL does:
-- - a. respond RAI(success=true, result code = SUCCESS) to both mobile apps
-- - b. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleType = common.modules[1]
local default = nil
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local defaultModuleNumber = 1
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
common.Step("App1 registration", common.registerAppWOPTU, { appSessionId1 })
common.Step("App2 registration", common.registerAppWOPTU, { appSessionId2 })
common.Step("App1 activation", common.activateApp, { appSessionId1 })
common.Step("App2 activation", common.activateApp, { appSessionId2 })
common.Step("App1 interiorVD subscription for " .. moduleType, common.GetInteriorVehicleData,
  { moduleType, default, common.IVDataSubscribeAction.subscribe,
    common.IVDataCacheState.isNotCached, default, appSessionId1 })
common.Step("App2 interiorVD subscription for " .. moduleType, common.GetInteriorVehicleData,
  { moduleType, default, common.IVDataSubscribeAction.subscribe,
      common.IVDataCacheState.isCached, default, appSessionId2 })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Open service for app1", common.sessionCreationOpenRPCservice, { appSessionId1 })
common.Step("Open service for app2", common.sessionCreationOpenRPCservice, { appSessionId2 })
common.Step("Reregister Apps resumption data", common.reRegisterApps,
  { checkResumptionData })
common.Step("Check subscription with OnInteriorVD " .. moduleType, common.onInteriorVD2Apps,
  { moduleType, expected, expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
