---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2454
--
-- Reproduction Steps:
-- HMI and SDL are started.
-- Register and activate Application1.
-- Register and activate Application2.
-- From HMI send notification OnExitAllApplication{reason = MASTER_RESET} to SDL.

-- Expected Behavior:
-- All SDL data are cleaned and reset.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local function HMISendToSDL_MASTER_RESET()
	common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
		  { reason = "MASTER_RESET" })
	common.getMobileSession(1):ExpectNotification("OnAppInterfaceUnregistered",
          { reason = "MASTER_RESET" })
	common.getMobileSession(2):ExpectNotification("OnAppInterfaceUnregistered",
          { reason = "MASTER_RESET" })
		  :ValidIf(function()
                local app_info_table = utils.jsonFileToTable(commonPreconditions:GetPathToSDL()  .. "/app_info.dat")
                local resumption_data = app_info_table.resumtion
        		if resumption_data == nil then
        			return true
        		else
                    print(" \27[36m Resumption data is not cleared after MASTER_RESET \27[0m")
        			return false
        		end
    		end)
	common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose",{})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerApp, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("PTU", common.policyTableUpdate)
runner.Step("Register App2", common.registerApp, { 2 })
runner.Step("Activate App2", common.activateApp, { 2 })
runner.Step("PTU", common.policyTableUpdate)

runner.Title("Test")

runner.Step("HMI send to SDL notification OnExitAllApplications reason=MASTER_RESET", HMISendToSDL_MASTER_RESET)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
