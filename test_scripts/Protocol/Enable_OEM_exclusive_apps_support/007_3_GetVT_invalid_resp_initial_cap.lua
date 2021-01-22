---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL uses the vehicle type data from the initial SDL capabilities file for StartServiceAck and
--  RAI response after the first SDL start when a file with cached capabilities is absent in case HMI responds with
--  invalid data to VI.GetVehicleType request
--
-- Steps:
-- 1. HMI provides BC.GetSystemInfo(ccpu_version)
-- 2. HMI responds with invalid data in vehicleType structure to VI.GetVehicleType requests
-- 3. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemSoftwareVersion value received from HMI in BC.GetSystemInfo response
--     via StartServiceAck to the app
--  - Provide the values for make, model, modelYear, trim parameters from the initial SDL capabilities file defined in
--     .ini file in HMICapabilities parameter via StartServiceAck to the app
-- 4. App sends RAI request via 5th protocol
-- SDL does:
--  - Provide systemSoftwareVersion value received from HMI in BC.GetSystemInfo response
--     via RAI response to the app
--  - Provide the values for make, model, modelYear, trim parameters from the initial SDL capabilities file defined in
--     .ini file in HMICapabilities parameter via RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local defaultVTD = common.vehicleTypeInfoParams.default
local customVTD = common.vehicleTypeInfoParams.custom
local vehicleTypeInfoParams = {
  make = defaultVTD.make,
  model = defaultVTD.model,
  modelYear = defaultVTD.modelYear,
  trim = defaultVTD.trim,
  ccpu_version = customVTD.ccpu_version
}

local hmiCap = common.setHMIcap(customVTD)
hmiCap.VehicleInfo.GetVehicleType.params.vehicleType.make = 12345 --invalid data type

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile, { defaultVTD })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { common.getRpcServiceAckParamsFromStruct(vehicleTypeInfoParams) })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

