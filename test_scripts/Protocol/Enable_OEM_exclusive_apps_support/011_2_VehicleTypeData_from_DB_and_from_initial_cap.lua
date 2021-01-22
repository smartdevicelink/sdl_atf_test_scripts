---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL is able to provide systemSoftwareVersion version from the DB and values for make, model, modelYear,
--  trim parameters from the initial SDL capabilities file in the second SDL ignition cycle
--
-- Steps:
-- 1. HMI responds with erroneous code to BC.GetSystemInfo request in the second ignition cycle,
--  systemSoftwareVersion has been saved to the DB in the previous ignition cycle
-- SDL does:
--  - Remove the cache file with hmi capabilities
--  - Request obtaining of all HMI capabilities and VI.GetVehicleType RPC
-- 2. HMI does not respond to VI.GetVehicleType request
-- 3. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemSoftwareVersion value from the DB in StartServiceAck to the app
--  - Provide the values for make, model, modelYear, trim parameters from the initial SDL capabilities file defined in
--     .ini file in HMICapabilities parameter via StartServiceAck to the app
-- 4. App requests RAI
-- SDL does:
--  - Provide systemSoftwareVersion value from the DB in RAI response to the app
--  - Provide the values for make, model, modelYear, trim parameters from the initial SDL capabilities file defined in
--     .ini file in HMICapabilities parameter via RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local initialVehicleTypeParams = {
  make = "OEM2",
  model = "Ranger",
  modelYear = "2021",
  trim = "Base"
}

local vehicleTypeInfoParams = {
  make = initialVehicleTypeParams.make,
  model = initialVehicleTypeParams.model,
  modelYear = initialVehicleTypeParams.modelYear,
  trim = initialVehicleTypeParams.trim,
  ccpu_version = common.vehicleTypeInfoParams.default.ccpu_version
}

local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function startErrorResponseGetSystemInfo()
  local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
  hmiCap.BasicCommunication.GetSystemInfo = nil
  hmiCap.VehicleInfo.GetVehicleType = nil
  common.start(hmiCap, common.isCacheNotUsed)
  common.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemInfo")
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
  end)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleType")
  common.wait(15000)
 end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile, { initialVehicleTypeParams })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { defaultHmiCap, common.isCacheNotUsed })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI sends GetSystemInfo(GENERIC_ERROR) response", startErrorResponseGetSystemInfo )
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { common.getRpcServiceAckParamsFromStruct(vehicleTypeInfoParams) })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

