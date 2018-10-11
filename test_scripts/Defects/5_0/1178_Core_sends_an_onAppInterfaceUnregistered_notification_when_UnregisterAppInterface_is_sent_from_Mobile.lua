---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1178
--
-- Description:
-- It seems as though we have an issue with core sending both an onAppInterfaceUnregistered 
-- notification and an UnregisterAppInterface response when the mobile proxy sends over 
-- UnregisterAppInterface. This should not be the case, as the notification should only be sent 
-- if there is an unregistration from the core side that was not caused by the mobile side. 
-- The notification also has a reason of -1, which is not a valid value.
-- We should remove the notification from being sent when the UnregisterAppInterface RPC is sent.
--
-- Preconditions: N/A
--
-- Steps: N/A
--
-- Expected result: N/A
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function unregisterAppInterface()
	local cid = common.getMobileSession():SendRPC("UnregisterAppInterface", { })
	common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", 
		{ appID = common.getHMIAppId(), unexpectedDisconnect = false})
	common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerApp)
runner.Step("Activate app", common.activateApp)

runner.Title("Test")
runner.Step("Unregister App Interface", unregisterAppInterface)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
