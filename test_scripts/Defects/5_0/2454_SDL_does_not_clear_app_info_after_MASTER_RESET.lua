---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2454
--
-- Reproduction Steps:
-- HMI and SDL are started.
-- Perform MASTER_RESET

-- Expected Behavior:
-- All SDL data are cleaned and reset.
---------------------------------------------------------------------------------------------------

-- For useing this script you must set actual path to binary file directory of SDL to 'config.pathToSDL' in cinfig.lua file.

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local config = require("modules/config")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local function HMISendToSDL_MASTER_RESET()
	common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
		  { reason = "MASTER_RESET" })
	common.getMobileSession(1):ExpectNotification("OnAppInterfaceUnregistered", 
          { reason = "MASTER_RESET" })
          :Times(1)
	common.getMobileSession(2):ExpectNotification("OnAppInterfaceUnregistered", 
          { reason = "MASTER_RESET" })
          :Times(1)
          :ValidIf(function(_, data)
          		local app_info_table = utils.jsonFileToTable(config.pathToSDL .. "/app_info.dat")
				local resume_app_list = app_info_table.resumption.resume_app_list
				if next(resume_app_list) ~= nil then
					return true
				else
					print("\27[App resumtion data wasn't cleaned.\27[0m")
					return false
				end
          	end)
	common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose",{})
	:Times(1)
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