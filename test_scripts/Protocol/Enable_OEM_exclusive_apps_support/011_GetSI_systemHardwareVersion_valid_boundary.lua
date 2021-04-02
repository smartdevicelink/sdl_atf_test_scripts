---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to process successfully the systemHardwareVersion parameter with
--  valid boundary value in BC.GetSystemInfo response
--
-- Steps:
-- 1. HMI sends BC.GetSystemInfo with valid boundary value of systemHardwareVersion parameter
-- SDL does:
--  - Process the response successfully
--  - Apply received systemHardwareVersion value
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemHardwareVersion value received from HMI in StartServiceAck to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local tcs = {
  [01] = string.rep("a", 500), --max value
  [02] = string.rep("a", 1) -- min value
}

--[[ Local Functions ]]
local function setHmiCap(pTC)
  local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
  local systemInfoParams = hmiCap.BasicCommunication.GetSystemInfo.params
  systemInfoParams.systemHardwareVersion = pTC
  return hmiCap
end

--[[ Scenario ]]
for tc, data in common.spairs(tcs) do
  common.Title("TC[" .. string.format("%03d", tc) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  local hmiCap = setHmiCap(data)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

  common.Title("Test")
  local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)
  common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
    common.startRpcService, { rpcServiceAckParams })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end

