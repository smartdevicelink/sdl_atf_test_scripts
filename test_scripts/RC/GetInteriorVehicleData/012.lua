---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 012
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Functions ]]
local function getModuleControlData(moduleType)
	if moduleType == "CLIMATE" then
		return commonRC.getClimateControlData()
	end
		return commonRC.getRadioControlData()
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
				moduleData = {
					moduleType = pModuleType,
					climateControlData = getModuleControlData(pModuleType)
				},
				isSubscribed = true
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
 				moduleData = {
					moduleType = pModuleType,
					climateControlData = getModuleControlData(pModuleType)
				},
				isSubscribed = true
			})
end

local function step(pModuleType, isSubscriptionActive, self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
		moduleDescription =	{
			moduleType = pModuleType
		},
		-- no subscribe parameter
	})

	EXPECT_HMICALL("RC.GetInteriorVehicleData", {
		appID = self.applications["Test Application"],
		moduleDescription =	{
			moduleType = pModuleType
		}
		-- no subscribe parameter
	})
  :Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
				moduleData = {
					moduleType = pModuleType,
					climateControlData = getModuleControlData(pModuleType)
				},
				isSubscribed = isSubscriptionActive -- return current value of subscription
			})
	end)

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
 				moduleData = {
					moduleType = pModuleType,
					climateControlData = getModuleControlData(pModuleType)
				}
				-- no isSubscribed parameter
			})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleData_CLIMATE_NoSubscription", step, {"CLIMATE", false})
runner.Step("GetInteriorVehicleData_RADIO_NoSubscription", step, {"RADIO", false})
runner.Step("Subscribe app to CLIMATE", subscribeToModule, {"CLIMATE"})
runner.Step("GetInteriorVehicleData_CLIMATE_ActiveSubscription_subscribe", step, {"CLIMATE", true})
runner.Step("Subscribe app to RADIO", subscribeToModule, {"RADIO"})
runner.Step("GetInteriorVehicleData_RADIO_ActiveSubscription_subscribe", step, {"RADIO", true})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
