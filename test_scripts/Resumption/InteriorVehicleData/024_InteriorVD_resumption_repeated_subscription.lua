---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App is subscribed to module_1
-- 2. Unexpected disconnect and connect are performed
-- 3. App is registered with actual hashID
-- 4. Resumption of the subscription for module_1 is performed successful
-- 5. App requests GetInteriorVD(subscribe=true, module_1)
-- SDL must:
-- 1. not send response to HMI
-- 2. respond GetInteriorVD(success = true, resultCode = WARNINGS) to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getInteriorVDWarning(pModuleType)
  local requestParams = {
    moduleType = pModuleType,
    subscribe = true
  }

  local cid = common.getMobileSession():SendRPC("GetInteriorVehicleData",requestParams)
  EXPECT_HMICALL("RC.GetInteriorVehicleData", requestParams)
  :Times(0)

  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "WARNINGS", moduleData = common.getModuleControlData(pModuleType), isSubscribed = true})

  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

local function checkResumptionData()
  common.checkModuleResumptionData(common.modules[1])
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU)
runner.Step("App1 activation", common.activateApp, { 1 })
runner.Step("Add interiorVD subscription for " .. common.modules[1],
  common.GetInteriorVehicleData, { common.modules[1], true, 1, 1 })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
-- runner.Step("Open service", common.openRPCservice, { 1 })
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, common.resumptionFullHMILevel})

runner.Title("Test")
runner.Step("GetInteriorVD with WARNINGS resultCode", getInteriorVDWarning, { common.modules[1] })
runner.Step("Check subscription with OnInteriorVD", common.onInteriorVD, { 1, common.modules[1], 1})
runner.Step("Check subscription with with GetInteriorVD(false)", common.GetInteriorVehicleData,
  { common.modules[1], false, 1, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
