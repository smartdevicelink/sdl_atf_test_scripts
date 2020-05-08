---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2464
--
-- Description:
-- SDL must send OnSDLClose by IGNITION_OFF
-- Precondition:
-- SDL and HMI are started.
-- App is registered.
-- In case:
-- 1) Perform IGNITION_OFF
-- Expected result:
-- 1) SDL receives OnExitAllApplications(SUSPEND) from HMI and sends OnSDLPersistenceComplete to HMI.
-- 2) SDL received OnExitAllApplications(IGNITION_OFF) from HMI, sends to mobile application OnAppInterfaceUnregistered(IGNITION_OFF) and OnAppUnregistered(unexpectedDisconnect = false)
-- 3) SDL sends to HMI OnSDLClose notification.
-- Actual result:
-- SDL does not send OnSDLClose notification to HMI by switching off with reason IGNITION_OFF.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function ignitionOff()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
    :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
        StopSDL()
      end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

-- [[ Test ]]
runner.Step("IGNITION_OFF", ignitionOff)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
