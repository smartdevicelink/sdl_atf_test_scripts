-- Requirement summary:
-- [Data Resumption]:OnExitAllApplications(IGNITION_OFF) in terms of resumption
--
-- Description:
-- In case SDL receives OnExitAllApplications(IGNITION_OFF),
-- SDL must clean up any resumption-related data
-- Obtained after OnExitAllApplications( SUSPEND). SDL must stop all its processes,
-- notify HMI via OnSDLClose and shut down.
--
-- 1. Used preconditions
-- HMI is running
-- One App is registered and activated on HMI
--
-- 2. Performed steps
-- Perform ignition Off
-- HMI sends OnExitAllApplications(IGNITION_OFF)
--
-- Expected result:
-- 1. SDL sends to App OnAppInterfaceUnregistered
-- 2. SDL sends to HMI OnSDLClose and stops working
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Functions ]]
local function expAppUnregistered()
  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Shutdown by IGNITION_OFF", common.ignitionOff, { expAppUnregistered })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
