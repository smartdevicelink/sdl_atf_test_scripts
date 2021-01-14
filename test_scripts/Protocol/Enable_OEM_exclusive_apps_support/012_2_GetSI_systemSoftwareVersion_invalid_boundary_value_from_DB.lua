---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to process correctly the systemHardwareVersion parameter with invalid value in
--  BC.GetSystemInfo response in the second ignition cycle
--
-- Steps:
-- 1. HMI sends BC.GetSystemInfo with invalid value of systemHardwareVersion parameter in the second ignition cycle,
-- systemSoftwareVersion and systemHardwareVersion parameter have values in the DB
-- SDL does:
--  - Process the response as invalid
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemHardwareVersion and systemSoftwareVersion values from the DB in StartServiceAck to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local tcs = {
  [01] = string.rep("a", 501), -- out of upper bound value
  [02] = "", -- out of lower bound value
  [03] = 1 -- invalid type
}
local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local vehicleTypeInfoParams = {
  make = common.vehicleTypeInfoParams.custom.make,
  model = common.vehicleTypeInfoParams.custom.model,
  modelYear = common.vehicleTypeInfoParams.custom.modelYear,
  trim = common.vehicleTypeInfoParams.custom.trim,
  ccpu_version = common.vehicleTypeInfoParams.default.ccpu_version,
  systemHardwareVersion = common.vehicleTypeInfoParams.default.systemHardwareVersion
}

--[[ Local Functions ]]
local function getRpcServiceAckParams(pVehicleTypeInfoParams)
  local ackParams = {
    make = common.setStringBsonValue(pVehicleTypeInfoParams.make),
    model = common.setStringBsonValue(pVehicleTypeInfoParams.model),
    modelYear = common.setStringBsonValue(pVehicleTypeInfoParams.modelYear),
    trim = common.setStringBsonValue(pVehicleTypeInfoParams.trim),
    systemSoftwareVersion = common.setStringBsonValue(pVehicleTypeInfoParams.ccpu_version),
    systemHardwareVersion = common.setStringBsonValue(pVehicleTypeInfoParams.systemHardwareVersion)
  }
  for key, KeyValue in pairs(ackParams) do
    if not KeyValue.value then
      ackParams[key] = nil
    end
  end
  return ackParams
end

local function setHmiCap(pTC, pVehicleTypeInfo)
  local hmiCap = common.setHMIcap(pVehicleTypeInfo)
  local systemInfoParams = hmiCap.BasicCommunication.GetSystemInfo.params
  systemInfoParams.systemHardwareVersion = pTC
  return hmiCap
end

--[[ Scenario ]]
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { defaultHmiCap, common.isCacheNotUsed })
  common.Step("Ignition off", common.ignitionOff)
  local customHmiCap = setHmiCap(data, common.vehicleTypeInfoParams.custom)

  common.Title("Test")
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { customHmiCap, common.isCacheNotUsed })
  common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService,
    { getRpcServiceAckParams(vehicleTypeInfoParams) })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
