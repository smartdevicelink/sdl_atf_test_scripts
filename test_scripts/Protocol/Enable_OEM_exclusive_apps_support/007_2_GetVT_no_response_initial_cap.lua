---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL uses the vehicle type data from the initial SDL capabilities file for StartServiceAck and
--  RAI response after the first SDL start when a file with cached capabilities is absent in case HMI does not respond
--  to VI.GetVehicleType request
--
-- Steps:
-- 1. HMI provides BC.GetSystemInfo(ccpu_version, systemHardwareVersion)
-- 2. HMI does not respond to VI.GetVehicleType requests
-- 3. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemSoftwareVersion and systemHardwareVersion values received from HMI in BC.GetSystemInfo response
--     via StartServiceAck to the app
--  - Provide the values for make, model, modelYear, trim parameters from the initial SDL capabilities file defined in
--     .ini file in HMICapabilities parameter via StartServiceAck to the app
-- 4. App sends RAI request via 5th protocol
-- SDL does:
--  - Provide systemSoftwareVersion value received from HMI in BC.GetSystemInfo response via RAI response to the app
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
  ccpu_version = customVTD.ccpu_version,
  systemHardwareVersion = customVTD.systemHardwareVersion
}

--[[ Local Functions ]]
local function startNoResponseGetVehicleType()
  local hmiCap = common.setHMIcap(customVTD)
  hmiCap.VehicleInfo.GetVehicleType = nil
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleType")
  :Do(function()
      -- do nothing
    end)
  common.start(hmiCap)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile, { defaultVTD })
common.Step("Start SDL, HMI does not send GetVehicleType response", startNoResponseGetVehicleType )

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { common.getRpcServiceAckParamsFromStruct(vehicleTypeInfoParams) })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

