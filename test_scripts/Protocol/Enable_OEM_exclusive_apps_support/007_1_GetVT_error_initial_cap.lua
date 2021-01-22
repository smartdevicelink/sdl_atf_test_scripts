---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL uses the vehicle type data from the initial SDL capabilities file for StartServiceAck and
--  RAI response after the first SDL start when a file with cached capabilities is absent in case HMI responds with
--  an erroneous result code to VI.GetVehicleType request at first SDL start
--
-- Steps:
-- 1. HMI provides BC.GetSystemInfo(ccpu_version)
-- 2. HMI responds with `GENERIC_ERROR` code to VI.GetVehicleType requests
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

--[[ Local Functions ]]
local function startErrorResponseGetVehicleType()
  local hmiCap = common.setHMIcap(customVTD)
  hmiCap.VehicleInfo.GetVehicleType = nil
  common.start(hmiCap)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleType")
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile, { defaultVTD })
common.Step("Start SDL, HMI sends GetSystemInfo(GENERIC_ERROR) response", startErrorResponseGetVehicleType )

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { common.getRpcServiceAckParamsFromStruct(vehicleTypeInfoParams) })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

