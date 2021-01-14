---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL is able to provide the updated vehicle type data to the mobile app in case ccpu version is updated
--  in the second SDL ignition cycle and HMI responds with updated data in VI.GetVehicleType response
--
-- Steps:
-- 1. HMI responds with new value of ccpu_version to BC.GetSystemInfo request in the second ignition cycle
-- SDL does:
--  - Remove the cache file with hmi capabilities
--  - Request obtaining of all HMI capabilities and VI.GetVehicleType RPC
-- 2. HMI responds with updated values to VI.GetVehicleType request
-- 3. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with parameter values received from HMI in StartServiceAck to the app
-- 4. App requests RAI
-- SDL does:
--  - Provide the vehicle type info with parameter values received from HMI in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local defaultHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local customHmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
local rpcServiceAckParams = common.getRpcServiceAckParams(customHmiCap)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { defaultHmiCap, common.isCacheNotUsed })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { customHmiCap, common.isCacheNotUsed })
common.Step("Start RPC Service, Vehicle type data in StartServiceAck",
  common.startRpcService, { rpcServiceAckParams })
common.Step("Vehicle type data in RAI", common.registerAppEx, { common.vehicleTypeInfoParams.custom })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
