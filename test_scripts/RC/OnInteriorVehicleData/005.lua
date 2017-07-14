---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
-- Script: 004
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Valiables ]]
local climateControlData = {
    fanSpeed = 50,
    currentTemp = 86,
    desiredTemp = 75,
    temperatureUnit = "FAHRENHEIT",
    acEnable = true,
    circulateAirEnable = true,
    autoModeEnable = true,
    defrostZone = "FRONT",
    dualModeEnable = true
}

local radioControlData = {
    frequencyInteger = 1,
    frequencyFraction = 2,
    band = "AM",
    rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 2,
        TP = false,
        TA = true,
        REG = "US"
      },
    availableHDs = 1,
    hdChannel = 1,
    signalStrength = 5,
    signalChangeThreshold = 20,
    radioEnable = true,
    state = "ACQUIRING"
}

--[[ Local Functions ]]
local function getModuleData(moduleType, moduleControlData)
    if moduleType == "CLIMATE" then
        return {moduleType = moduleType, climateControlData = moduleControlData or commonRC.getClimateControlData()}
    end
    return {moduleType = moduleType, radioControlData = moduleControlData or commonRC.getRadioControlData()}
end

local function subscriptionToModule(pModuleType, pResultCode, self)
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
		self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = pResultCode})
end

local function stepUnsubscribed(pModuleType, pModuleControlData, self)
    self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
            moduleData = getModuleData(pModuleType, pModuleControlData)
      })

  EXPECT_NOTIFICATION("OnInteriorVehicleData", {}):Times(0)
  commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("Subscribe app to CLIMATE (GENERIC_ERROR from HMI)", subscriptionToModule, {"CLIMATE", "GENERIC_ERROR"})
runner.Step("Send notification OnInteriorVehicleData_CLIMATE. App is not subscribed", stepUnsubscribed, {"CLIMATE", climateControlData})
runner.Step("Subscribe app to CLIMATE (INVALID_DATA from HMI)", subscriptionToModule, {"CLIMATE", "INVALID_DATA"})
runner.Step("Send notification OnInteriorVehicleData_CLIMATE. App is not subscribed", stepUnsubscribed, {"CLIMATE", climateControlData})
runner.Step("Subscribe app to CLIMATE (OUT_OF_MEMORY from HMI)", subscriptionToModule, {"CLIMATE", "OUT_OF_MEMORY"})
runner.Step("Send notification OnInteriorVehicleData_CLIMATE. App is not subscribed", stepUnsubscribed, {"CLIMATE", climateControlData})
runner.Step("Subscribe app to CLIMATE (REJECTED from HMI)", subscriptionToModule, {"CLIMATE", "REJECTED"})
runner.Step("Send notification OnInteriorVehicleData_CLIMATE. App is not subscribed", stepUnsubscribed, {"CLIMATE", climateControlData})
runner.Step("Subscribe app to RADIO (GENERIC_ERROR from HMI)", subscriptionToModule, {"RADIO", "GENERIC_ERROR"})
runner.Step("Send notification OnInteriorVehicleData RADIO. App is not subscribed", stepUnsubscribed, {"RADIO", radioControlData})
runner.Step("Subscribe app to RADIO (INVALID_DATA from HMI)", subscriptionToModule, {"RADIO", "INVALID_DATA"})
runner.Step("Send notification OnInteriorVehicleData RADIO. App is not subscribed", stepUnsubscribed, {"RADIO", radioControlData})
runner.Step("Subscribe app to RADIO (OUT_OF_MEMORY from HMI)", subscriptionToModule, {"RADIO", "OUT_OF_MEMORY"})
runner.Step("Send notification OnInteriorVehicleData RADIO. App is not subscribed", stepUnsubscribed, {"RADIO", radioControlData})
runner.Step("Subscribe app to RADIO (REJECTED from HMI)", subscriptionToModule, {"RADIO", "REJECTED"})
runner.Step("Send notification OnInteriorVehicleData RADIO. App is not subscribed", stepUnsubscribed, {"RADIO", radioControlData})
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
