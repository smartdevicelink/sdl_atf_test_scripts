---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleDataCapabilities
-- Script: 015
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')

--[[ Local Variables ]]
local interiorVehicleDataCapabilitiesTable = {
	interiorVehicleDataCapabilities = {
		climateVehicleCapabilities = {
			circulateAirEnableAvailable = false,
      defrostZone = "ALL",
      defrostZoneAvailable = true,
      desiredTemperatureAvailable = false,
      dualModeEnableAvailable = true,
      fanSpeedAvailable = false,
      name =  "Climate control module",
      fake_param = "bad param", -- fake param
		},
		radioControlCapabilities = {
      availableHDsAvailable = false,
      hdChannelAvailable = true,
      name = "Radio control module",
      radioBandAvailable = 128.3, -- wrong type
      radioEnableAvailable = false,
      radioFrequencyAvailable = false,
      rdsDataAvailable = false,
      signalChangeThresholdAvailable = "true", -- wrong type
      signalStrengthAvailable = false,
      stateAvailable = false
    }
	}
}

--[[ Local Functions ]]
local function step(module_types, self)
	local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities", {
			moduleTypes = module_types
		})

	EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities", {
			appID = self.applications["Test Application"],
			moduleTypes = module_types
		})
	:Do(function(_, data)
		self.hmiConnection:SendError(data.id, data.method, "READ_ONLY", "Read only parameters")
	end)

	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Prepare InteriorVehicleDataCapabilities.json", commonRC.prepareInteriorVehicleDataCapabilitiesJson, {interiorVehicleDataCapabilitiesTable})
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleDataCapabilities_CLIMATE", step, { { "CLIMATE" } })
runner.Step("GetInteriorVehicleDataCapabilities_RADIO", step, { { "RADIO" } })
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
