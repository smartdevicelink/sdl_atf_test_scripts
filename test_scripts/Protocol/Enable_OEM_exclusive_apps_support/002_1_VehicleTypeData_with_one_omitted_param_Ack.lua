---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide some part of the vehicle type data in StartServiceAck right after
--  receiving both GetVehicleType and GetSystemInfo responses
--
-- Steps:
-- 1. HMI provides some part of vehicle type data in BC.GetSystemInfo and VI.GetVehicleType responses:
--  - BC.GetSystemInfo(ccpu_version) and VI.GetVehicleType(make, model, modelYear)
--  - BC.GetSystemInfo(ccpu_version) and VI.GetVehicleType(make, model, trim)
--  - BC.GetSystemInfo(ccpu_version) and VI.GetVehicleType(make, modelYear, trim)
--  - BC.GetSystemInfo(ccpu_version) and VI.GetVehicleType(model, modelYear, trim)
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with parameter values received from HMI in StartServiceAck to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local tcs = {
  [01] = "make",
  [02] = "model",
  [03] = "modelYear",
  [04] = "trim"
}

--[[ Local Functions ]]
local function setHMICap(pParamToExclude)
  local defaultVehicleTypeInfoParam = common.cloneTable(common.vehicleTypeInfoParams.default)
  defaultVehicleTypeInfoParam[pParamToExclude] = nil
  local out = common.setHMIcap(defaultVehicleTypeInfoParam)
  return out
end

local function startRpcService(pAckParams, pNotExpected)
  common.startRpcService(pAckParams)
  :ValidIf(function(_, data)
    local errorMessages = ""
    local actPayload = common.bson_to_table(data.binaryData)
    for Key, _ in pairs(actPayload) do
      if Key == pNotExpected then
        errorMessages = errorMessages .. "BinaryData contains unexpected " .. pNotExpected .. " parameter\n"
      end
    end
    if string.len(errorMessages) > 0 then
      return false, errorMessages
    else
      return true
    end
  end)
end

--[[ Scenario ]]
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = setHMICap(data)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

  common.Title("Test")
  common.Step("Vehicle type data without " .. data .. " in StartServiceAck", startRpcService,
    { common.getRpcServiceAckParams(hmiCap), data })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
