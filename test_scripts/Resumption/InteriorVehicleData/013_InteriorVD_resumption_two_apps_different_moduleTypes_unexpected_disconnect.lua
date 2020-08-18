---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data for two apps after transport disconnect
--  in case apps are subscribed to different moduleTypes
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app1 and app2 with REMOTE_CONTROL hmi type are registered and activated
-- 3. App1 is subscribed to module_1
-- 4. App2 is subscribed to module_2
--
-- Sequence:
-- 1. Transport disconnect and reconnect are performed
-- 2. Apps start registration with actual hashIds after unexpected disconnect
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(module_1) and RC.GetInteriorVehicleData(module_2) to HMI during resumption data
-- - b. respond RAI(SUCCESS) to both mobile apps
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleTypeForApp1 = common.modules[1]
local moduleTypeForApp2 = common.modules[2]
local isSubscribe = true
local default = nil
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1
local notExpected = 0

--[[ Local Functions ]]
local function checkResumptionData()
  local defaultModuleNumber = 1
  local modulesCount = 2
  local expectedModules = {
    {
      moduleType = moduleTypeForApp1,
      subscribe = true,
      moduleId = common.getModuleId(moduleTypeForApp1, defaultModuleNumber)
    },
    {
      moduleType = moduleTypeForApp2,
      subscribe = true,
      moduleId = common.getModuleId(moduleTypeForApp2, defaultModuleNumber)
    }
  }

  common.checkResumptionData(modulesCount, expectedModules, true)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App1 registration", common.registerAppWOPTU, { appSessionId1 })
common.Step("App2 registration", common.registerAppWOPTU, { appSessionId2 })
common.Step("App1 activation", common.activateApp, { appSessionId1 })
common.Step("App2 activation", common.activateApp, { appSessionId2 })
common.Step("App1 interiorVD subscription for " .. moduleTypeForApp1,
  common.GetInteriorVehicleData, { moduleTypeForApp1, default, isSubscribe, default, default, appSessionId1 })
common.Step("App2 interiorVD subscription for " .. moduleTypeForApp2,
  common.GetInteriorVehicleData, { moduleTypeForApp2, default, isSubscribe, default, default, appSessionId2 })

common.Title("Test")
common.Step("Unexpected disconnect", common.mobileDisconnect)
common.Step("Connect mobile", common.mobileConnect)
common.Step("Open service for app1", common.sessionCreationOpenRPCservice, { appSessionId1 })
common.Step("Open service for app2", common.sessionCreationOpenRPCservice, { appSessionId2 })
common.Step("Reregister Apps resumption data", common.reRegisterApps, { checkResumptionData })
common.Step("Check subscription with OnInteriorVD " .. moduleTypeForApp1, common.onInteriorVD2Apps,
  { moduleTypeForApp1, expected, notExpected })
common.Step("Check subscription with OnInteriorVD " .. moduleTypeForApp2, common.onInteriorVD2Apps,
  { moduleTypeForApp2, notExpected, expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
