---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide some part of the vehicle type data in RAI response after
--  receiving both GetVehicleType and GetSystemInfo responses only with mandatory parameters
--
-- Steps:
-- 1. HMI provides only mandatory parameters of vehicle type data in BC.GetSystemInfo and VI.GetVehicleType responses:
--  - BC.GetSystemInfo(ccpu_version) and VI.GetVehicleType(without parameters)
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type data received from HMI in StartServiceAck to the app
-- 3. App sends RAI request via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with parameter values received from HMI in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local vehicleData = {
  ccpu_version = common.vehicleTypeInfoParams.default["ccpu_version"]
}

--[[ Scenario ]]
common.Title("Test with excluding all not mandatory parameters")
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
local hmiCap = common.setHMIcap(vehicleData)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Vehicle type data without all not mandatory params in StartServiceAck", common.startRpcService,
  { common.getRpcServiceAckParams(hmiCap) })
common.Step("Vehicle type data without all not mandatory params in RAI response", common.registerAppEx, { vehicleData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
