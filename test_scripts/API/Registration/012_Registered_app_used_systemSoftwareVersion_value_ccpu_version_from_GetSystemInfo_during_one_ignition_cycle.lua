---------------------------------------------------------------------------------------------------
-- Regression check
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- Check that SDL used for param systemSoftwareVersion value "ccpu_version" from "GetSystemInfo" during one ignition cycle
-- In case:
-- 1) Mobile application is registered.
-- 2) Mobile app is re-registered.
-- SDL does:
-- 1) Successfully re-register application.
-- 2) Not send GetSystemInfo during RegisterAppInterface.
-- 3) Used for param systemSoftwareVersion value "ccpu_version" from "GetSystemInfo" during one ignition cycle
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local systemSoftwareVersionValue = "FORD"

local valueForResponse = {
  systemSoftwareVersion =  systemSoftwareVersionValue
}

--[[ Local Functions ]]
local function getHMIValuesDuringFirstRAI()
  local params = hmi_values.getDefaultHMITable()
    params.BasicCommunication.GetSystemInfo.params.ccpu_version = "FORD"
    params.BasicCommunication.GetSystemInfo.params.language = "EN-US"
    params.BasicCommunication.GetSystemInfo.params.wersCountryCode = "user_wersCountryCode"
  return params
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start, { getHMIValuesDuringFirstRAI () })

runner.Title("Test")
runner.Step("SystemSoftwareVersion in RAI response during first registration",
	common.registerApp, { 1, common.getRequestParams(1), _, valueForResponse })
runner.Step("Application unregistered", common.unregisterAppInterface)
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("SDL used the same value of systemSoftwareVersion",
	common.registerApp, { 1, common.getRequestParams(1), _, valueForResponse})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
