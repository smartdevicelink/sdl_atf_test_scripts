---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data for two apps after IGN_OFF in case apps are subscribed to
--  the same and different moduleTypes
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app1 and app2 with REMOTE_CONTROL hmi type are registered and activated
-- 3. App1 is subscribed to module_1 and module_2
-- 4. App2 is subscribed to module_2 and module_3
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. Apps start registration with actual hashIds after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(module_1, default_moduleId),
--    RC.GetInteriorVehicleData(module_2, default_moduleId)
--    and RC.GetInteriorVehicleData(module_3, default_moduleId) to HMI during resumption data
-- - b. respond RAI(SUCCESS) to both mobile apps
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribe = true
local default = nil
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1
local notExpected = 0
local isNotCashed = false
local isCashed = true

--[[ Local Functions ]]
local function checkResumptionData()
  local modulesCount = 3
  local expectedModules = common.getExpectedDataSomeModules(modulesCount)
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
common.Step("App1 interiorVD subscription for " .. common.modules[1],
  common.GetInteriorVehicleData, { common.modules[1], default, isSubscribe, isNotCashed, default, appSessionId1 })
common.Step("App1 interiorVD subscription for " .. common.modules[2],
  common.GetInteriorVehicleData, { common.modules[2], default, isSubscribe, isNotCashed, default, appSessionId1 })
common.Step("App2 interiorVD subscription for " .. common.modules[2],
  common.GetInteriorVehicleData, { common.modules[2], default, isSubscribe, isCashed, default, appSessionId2 })
common.Step("App2 interiorVD subscription for " .. common.modules[3],
  common.GetInteriorVehicleData, { common.modules[3], default, isSubscribe, isNotCashed, default, appSessionId2  })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Open service for app1", common.sessionCreationOpenRPCservice, { appSessionId1 })
common.Step("Open service for app2", common.sessionCreationOpenRPCservice, { appSessionId2 })
common.Step("Reregister Apps resumption data", common.reRegisterApps,
  { checkResumptionData })
common.Step("Check subscription with OnInteriorVD " .. common.modules[1], common.onInteriorVD2Apps,
  { common.modules[1], expected, notExpected })
common.Step("Check subscription with OnInteriorVD " .. common.modules[2], common.onInteriorVD2Apps,
  { common.modules[2], expected, expected })
common.Step("Check subscription with OnInteriorVD " .. common.modules[3], common.onInteriorVD2Apps,
  { common.modules[3], notExpected, expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
