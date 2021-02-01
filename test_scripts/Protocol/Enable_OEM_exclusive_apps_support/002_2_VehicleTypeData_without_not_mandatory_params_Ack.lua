---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide some part of the vehicle type data in StartServiceAck right after
--  receiving both GetVehicleType and GetSystemInfo responses only with mandatory parameters
--
-- Steps:
-- 1. HMI provides only mandatory parameters of vehicle type data in BC.GetSystemInfo and VI.GetVehicleType responses:
--  - BC.GetSystemInfo(ccpu_version) and VI.GetVehicleType(without parameters)
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with parameter values received from HMI in StartServiceAck to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local vehicleTypeData = {
  ccpu_version = common.vehicleTypeInfoParams.default["ccpu_version"]
}

--[[ Local Functions ]]
local function startRpcService(pAckParams)
  local excludedParams = { "make","model", "modelYear", "trim", "systemHardwareVersion" }
  common.startRpcService(pAckParams)
  :ValidIf(function(_, data)
    local errorMessages = ""
    local actPayload = common.bson_to_table(data.binaryData)
    for _, param in pairs(excludedParams) do
      for Key, _ in pairs(actPayload) do
        if Key == param then
          errorMessages = errorMessages .. "BinaryData contains unexpected " .. param .. " parameter\n"
        end
      end
    end
    if string.len(errorMessages) > 0 then
      return false, errorMessages
    end
    return true
  end)
end

--[[ Scenario ]]
common.Title("Test with excluding all not mandatory parameters")
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
local hmiCap = common.setHMIcap(vehicleTypeData)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Vehicle type data without all not mandatory params in StartServiceAck", startRpcService,
  { common.getRpcServiceAckParams(hmiCap) })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
