---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide all vehicle type data RAI response after receiving
--  BC.GetSystemInfo and VI.GetVehicleType responses with parameters except systemHardwareVersion
--
-- Steps:
-- 1. HMI provides all vehicle type data in BC.GetSystemInfo(ccpu_version, systemHardwareVersion)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with all parameter values received from HMI in StartServiceAck to the app
-- 3. App sends RAI request via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with all parameter values received from HMI except systemHardwareVersion in
--   RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService, { rpcServiceAckParams })
common.Step("Vehicle type data in RAI response", common.registerAppEx, { common.vehicleTypeInfoParams.default })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
