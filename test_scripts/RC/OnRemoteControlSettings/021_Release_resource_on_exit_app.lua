---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 3: Alternative Flow 1
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- SDL received OnExitApplication (either user exits RC_app_1 vis HMI or due to driver distraction violation)
--
-- SDL must:
-- 1) SDL assigns HMILevel NONE to RC_app_1 and releases module_1 from RC_app_1 control
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local exitAppReasons = {"USER_EXIT", "DRIVER_DISTRACTION_VIOLATION"}

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
  table.insert(tbl.policy_table.functional_groupings.RemoteControl.rpcs.OnInteriorVehicleData.hmi_levels, "NONE")
end

local function exitApp(pReason, pAppId, self)
	local hmiAppId = commonRC.getHMIAppId(pAppId)
	local mobSession = commonRC.getMobileSession(self, pAppId)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
		{ appID = hmiAppId, reason = pReason })
	mobSession:ExpectNotification("OnHMIStatus",
		{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("RAI2", commonRC.rai_n, { 2 })

runner.Title("Test")
runner.Step("Enable RC from HMI with AUTO_DENY access mode", commonRC.defineRAMode, { true, "AUTO_DENY"})
for _, reason in pairs(exitAppReasons) do
	runner.Title("Exit reason " .. reason)
	runner.Step("Activate App2", commonRC.activate_app, { 2 })
	runner.Step("Activate App1", commonRC.activate_app)
	-- App1: FULL, App2: BACKGROUND
	runner.Step("Module CLIMATE App1 ButtonPress allowed", commonRC.rpcAllowed, { "CLIMATE", 1, "ButtonPress" })
	runner.Step("Subscribe App1 to CLIMATE", commonRC.subscribeToModule, { "CLIMATE", 1 })
	runner.Step("Send notification OnInteriorVehicleData CLIMATE. App1 is subscribed", commonRC.isSubscribed, { "CLIMATE", 1 })
	runner.Step("Module CLIMATE App2 SetInteriorVehicleData denied", commonRC.rpcDenied, { "CLIMATE", 2, "SetInteriorVehicleData", "REJECTED" })
	runner.Step("Exit App1 with reason " .. reason, exitApp, { reason, 1})
	-- App1: NONE, App2: BACKGROUND
	runner.Step("Send notification OnInteriorVehicleData CLIMATE. App1 is unsubscribed", commonRC.isUnsubscribed, { "CLIMATE", 1 })
	runner.Step("Module CLIMATE App2 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "CLIMATE", 2, "SetInteriorVehicleData"})
	runner.Step("Exit App2 with reason " .. reason, exitApp, { reason, 2})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
