---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to process correctly the systemHardwareVersion parameter with invalid value in
--  BC.GetSystemInfo response in the first ignition cycle
--
-- Steps:
-- 1. HMI sends BC.GetSystemInfo with invalid value of systemHardwareVersion parameter in the first ignition cycle,
-- systemSoftwareVersion and systemHardwareVersion parameter are empty in the DB
-- SDL does:
--  - Process the response as invalid
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Not provide systemHardwareVersion and systemSoftwareVersion values in StartServiceAck to the app
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
local rpcServiceAckParams = common.getRpcServiceAckParams(defaultHmiCap)
rpcServiceAckParams.systemSoftwareVersion = nil
rpcServiceAckParams.systemHardwareVersion = nil

local notExpected = { "systemSoftwareVersion", "systemHardwareVersion" }

--[[ Local Functions ]]
local function setHmiCap(pTC)
  local hmiCap = common.cloneTable(defaultHmiCap)
  local systemInfoParams = hmiCap.BasicCommunication.GetSystemInfo.params
  systemInfoParams.systemHardwareVersion = pTC
  return hmiCap
end

local function startRpcService(pAckParams, pAppId)
  common.startRpcService(pAckParams, pAppId)
  :ValidIf(function(_, data)
    local errorMessages = ""
    local actPayload = common.bson_to_table(data.binaryData)
    for _, param in pairs(notExpected) do
      for Key, _ in pairs(actPayload) do
        if Key == param then
          errorMessages = errorMessages .. "BinaryData contains unexpected " .. param .. " parameter\n"
        end
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
  local hmiCap = setHmiCap(data)

  common.Title("Test")
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })
  common.Step("Start RPC Service, Vehicle type data in StartServiceAck", startRpcService,
    { rpcServiceAckParams })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
