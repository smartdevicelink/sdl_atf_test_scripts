---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL is able to provide systemSoftwareVersion version from the DB and updated values from
--  VI.GetVehicleType response in the second SDL ignition cycle
--
-- Steps:
-- 1. HMI responds with erroneous code to BC.GetSystemInfo request in the second ignition cycle,
--  systemSoftwareVersion has been saved to the DB in the previous ignition cycle
-- SDL does:
--  - Remove the cache file with hmi capabilities
--  - Request obtaining of all HMI capabilities and VI.GetVehicleType RPC
-- 2. HMI responds with updated values to VI.GetVehicleType request
-- 3. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemSoftwareVersion value from the DB in StartServiceAck to the app
--  - Provide the values for make, model, modelYear, trim parameters received from HMI in StartServiceAck to the app
-- 4. App requests RAI
-- SDL does:
--  - Provide systemSoftwareVersion value from the DB in RAI response to the app
--  - Provide the values for make, model, modelYear, trim parameters received from HMI in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local vehicleTypeInfoParams = {
  make = common.vehicleTypeInfoParams.custom.make,
  model = common.vehicleTypeInfoParams.custom.model,
  modelYear = common.vehicleTypeInfoParams.custom.modelYear,
  trim = common.vehicleTypeInfoParams.custom.trim,
  ccpu_version = common.vehicleTypeInfoParams.default.ccpu_version
}

local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function startErrorResponseGetSystemInfo()
  local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
  hmiCap.BasicCommunication.GetSystemInfo = nil
  common.start(hmiCap, common.isCacheNotUsed)
  common.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemInfo")
  :Do(function(_, data)
    common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { defaultHmiCap, common.isCacheNotUsed })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI sends GetSystemInfo(GENERIC_ERROR) response", startErrorResponseGetSystemInfo )
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { common.getRpcServiceAckParamsFromStruct(vehicleTypeInfoParams) })
common.Step("Vehicle type data in RAI", common.registerAppEx, { vehicleTypeInfoParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

