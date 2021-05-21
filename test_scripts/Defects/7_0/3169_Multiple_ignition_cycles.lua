---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3169
---------------------------------------------------------------------------------------------------
-- Description:
-- Successful processing of multiple ignition (OFF/ON) cycles
--
-- Preconditions:
-- 1. Clean environment
-- 2. SDL, HMI, Mobile session are started
-- 3. App is registered and activated
-- Steps:
-- 1. HMI sends OnExitAllApplications(IGNITION_OFF) notification to SDL
-- SDL does:
--  - sends BasicCommunication.OnSDLClose notification to HMI and stops working
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local numOfItr = 50

--[[ Local Functions ]]
local function ignitionOff()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      SDL.DeleteFile()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Title("Test")

for i = 1, numOfItr do
  runner.Title("Iteration " .. i)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Register App", common.registerAppWOPTU)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Ignition Off", ignitionOff)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
