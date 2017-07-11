---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleDataCapabilities
-- Script: 018
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local runner = require('user_modules/script_runner')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Local Variables ]]
local interiorVehicleDataCapabilitiesTable = {
  interiorVehicleDataCapabilities = commonRC.getInteriorVehicleDataCapabilities({"RADIO", "CLIMATE"})
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
    self.hmiConnection:SendError(data.id, data.method, "INVALID_DATA", "Invalid data")
	end)

	EXPECT_RESPONSE(cid, {
    success = true,
    resultCode = "SUCCESS",
    interiorVehicleDataCapabilities = commonRC.getInteriorVehicleDataCapabilities(module_types)
    })

end

local function setEmptyInteriorVDCapabilitiesFile()
  commonFunctions:write_parameter_to_smart_device_link_ini("InteriorVDCapabilitiesFile", "")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Prepare InteriorVehicleDataCapabilities.json",
  commonRC.prepareInteriorVehicleDataCapabilitiesJson,
  {interiorVehicleDataCapabilitiesTable, "InteriorVehicleDataCapabilities.json"})
runner.Step("Set empty InteriorVDCapabilitiesFile field in smartDeviceLink.ini", setEmptyInteriorVDCapabilitiesFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Title("Test")
runner.Step("GetInteriorVehicleDataCapabilities_CLIMATE", step, { { "CLIMATE" } })
runner.Step("GetInteriorVehicleDataCapabilities_RADIO", step, { { "RADIO" } })
runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)