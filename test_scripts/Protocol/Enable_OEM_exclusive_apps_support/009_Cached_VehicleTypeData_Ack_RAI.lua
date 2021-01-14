---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL uses the vehicle type data from the file with cached capabilities for StartServiceAck and
--  RAI response at the second SDL start
--
-- Steps:
-- 1. All vehicle type data is provided via BC.GetSystemInfo(ccpu_version, systemHardwareVersion)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses and cached in previous ignition cycle
-- 2. HMI and SDL start
-- SDL does:
--  - not request VI.GetVehicleType RPC
--  - request BC.GetSystemInfo RPC
-- 3. HMI sends BC.GetSystemInfo(ccpu_version, systemHardwareVersion) response
-- 4. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide systemSoftwareVersion and systemHardwareVersion values received from HMI in BC.GetSystemInfo response
--     via StartServiceAck to the app
--  - Provide the values for make, model, modelYear, trim parameters from cached HMI capabilities
--     in StartServiceAck to the app
-- 5. App requests RAI
-- SDL does:
--  - Provide systemSoftwareVersion and systemHardwareVersion values received from HMI in BC.GetSystemInfo response
--     via RAI response to the app
--  - Provide the values for make, model, modelYear, trim parameters from cached HMI capabilities
--     in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.custom)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)
local isCacheUsed = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile, { common.vehicleTypeInfoParams.default })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI does not send GetSystemInfo request",
  common.start, { hmiCap, isCacheUsed })
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService, { rpcServiceAckParams })
common.Step("Vehicle type data in RAI", common.registerAppEx, { common.vehicleTypeInfoParams.custom })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
