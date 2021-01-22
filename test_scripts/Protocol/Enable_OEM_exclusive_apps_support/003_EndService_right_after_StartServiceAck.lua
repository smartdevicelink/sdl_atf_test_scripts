---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL is able to stop RPC service successfully in case the mobile app does not support
--  the vehicle type data received from SDL and requests EndService after StartServiceAck
--
-- Steps:
-- 1. HMI provides all vehicle type data in BC.GetSystemInfo(ccpu_version)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with all parameter values received from HMI in StartServiceAck to the app
-- 3. App does not support the data from received vehicle type info and requests EndService
-- SDL does:
--  - End RPC service successfully and sends EndServiceAck to the app
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
common.Step("EndService", common.endRPCService)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
