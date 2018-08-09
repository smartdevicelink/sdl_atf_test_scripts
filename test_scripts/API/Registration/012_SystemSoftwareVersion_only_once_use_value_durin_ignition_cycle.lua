---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Check that SDL request systemSoftwareVersion only once and use this value during ignition cycle.
-- SDL does:
-- 1) Does not send GetSystemInfo during RegisterAppInterface.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getHMIValuesDuringFirstRAI()
    local params = hmi_values.getDefaultHMITable()
        params.BasicCommunication.GetSystemInfo.params.ccpu_version = "FORD"
        params.BasicCommunication.GetSystemInfo.params.language = "EN-US"
        params.BasicCommunication.GetSystemInfo.params.wersCountryCode = "user_wersCountryCode"
    return params
end

local function getHMIValuesDuringSecondRAI()
    local params = hmi_values.getDefaultHMITable()
        params.BasicCommunication.GetSystemInfo.params.ccpu_version = "FORD_second_ignition_cycle"
        params.BasicCommunication.GetSystemInfo.params.language = "EN-US"
        params.BasicCommunication.GetSystemInfo.params.wersCountryCode = "user_wersCountryCode"
    return params
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start, { getHMIValuesDuringFirstRAI () })

runner.Title("Test")
runner.Step("SystemSoftwareVersion in RAI response during first registration", common.registerApp)
runner.Step("Application unregistered", common.unregisterAppInterface)
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("SystemSoftwareVersion in RAI response during second registration", common.registerApp)
runner.Step("Stop SDL", common.postconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start, { getHMIValuesDuringSecondRAI () })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
