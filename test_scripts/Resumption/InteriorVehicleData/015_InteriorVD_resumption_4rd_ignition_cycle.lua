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
-- 2. IGN_OFF and IGN_ON are performed
-- 3. IGN_OFF and IGN_ON are performed
-- 4. IGN_OFF and IGN_ON are performed
-- 5. App starts registration with actual hashId after IGN_ON in 4th ignition cycle
-- SDL does:
-- 1. not resume persistent data - not send RC.GetInteriorVD(subscribe=true, module_1)
-- 2. respond RAI(RESUME_FAILED) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkResumptionData()
  EXPECT_HMICALL("RC.GetInteriorVehicleData")
  :Times(0)
end

local function absenceHMIlevelResumption()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  common.wait()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Add interiorVD subscription", common.GetInteriorVehicleData, { common.modules[1], true, 1, 1 })

runner.Title("Test")
runner.Step("IGNITION_OFF", common.ignitionOff)
runner.Step("IGNITION_ON", common.start)
runner.Step("IGNITION_OFF", common.ignitionOff)
runner.Step("IGNITION_ON", common.start)
runner.Step("IGNITION_OFF", common.ignitionOff)
runner.Step("IGNITION_ON", common.start)
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, absenceHMIlevelResumption, "RESUME_FAILED" })
runner.Step("Check subscription", common.GetInteriorVehicleData, { common.modules[1], false, 1, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

