---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 011
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function getModuleData(moduleType)
	if moduleType == "CLIMATE" then
		return {moduleType = moduleType, climateControlData = commonRC.getClimateControlData()}
	end
	return {moduleType = moduleType, radioControlData = commonRC.getRadioControlData()}
end

local function subscribeToModule(pModuleType, self)

	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = pModuleType
		},
		subscribe = true
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = pModuleType
		},
		subscribe = true
	})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = getModuleData(pModuleType),
				isSubscribed = true
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
 				moduleData = getModuleData(pModuleType),
				isSubscribed = true
			})
end

local function step(pModuleType, isSubscriptionActive, pSubscribe, self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = pModuleType
		},
		subscribe = pSubscribe
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = pModuleType
		},
		subscribe = pSubscribe
	})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = getModuleData(pModuleType),
				-- no isSubscribed parameter
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
				isSubscribed = isSubscriptionActive, -- return current value of subscription
 				moduleData = getModuleData(pModuleType)
			})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE_NoSubscription_subscribe", step, {"CLIMATE", false, true})
runner.Step("GetInteriorVehicleData_CLIMATE_NoSubscription_unsubscribe", step, {"CLIMATE", false, false})
runner.Step("GetInteriorVehicleData_RADIO_NoSubscription_subscribe", step, {"RADIO", false, true})
runner.Step("GetInteriorVehicleData_RADIO_NoSubscription_unsubscribe", step, {"RADIO", false, false})
runner.Step("Subscribe app to CLIMATE", subscribeToModule, {"CLIMATE"})
runner.Step("GetInteriorVehicleData_CLIMATE_ActiveSubscription_subscribe", step, {"CLIMATE", true, true})
runner.Step("GetInteriorVehicleData_CLIMATE_ActiveSubscription_unsubscribe", step, {"CLIMATE", true, false})
runner.Step("Subscribe app to RADIO", subscribeToModule, {"RADIO"})
runner.Step("GetInteriorVehicleData_RADIO_ActiveSubscription_subscribe", step, {"RADIO", true, true})
runner.Step("GetInteriorVehicleData_RADIO_ActiveSubscription_unsubscribe", step, {"RADIO", true, false})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
