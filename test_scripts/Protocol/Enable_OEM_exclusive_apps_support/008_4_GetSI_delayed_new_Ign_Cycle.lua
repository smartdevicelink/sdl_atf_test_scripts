---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to postpone sending of StartServiceAck in case HMI responds with delay to
--  BC.GetSystemInfo request, VI.GetVehicleType is not requested because the data from VI.GetVehicleType have been
--  cached in the previous ignition cycle
--
-- Steps:
-- 1. SDL requests BC.GetSystemInfo to HMI after start
-- 2. Vehicle type data is cached in the previous ignition cycle(SDL does not request VI.GetVehicleType)
-- 2. App requests StartService(RPC) via 5th protocol
-- SDL does:
--  - Postpone the sending of StartServiceAck before receiving of BC.GetSystemInfo response
-- 3. HMI responds with delay to BC.GetSystemInfo request
-- SDL does:
--  - Send StartServiceAck right after receiving BC.GetSystemInfo response
--  - Provide systemSoftwareVersion value received from HMI in BC.GetSystemInfo response
--     via StartServiceAck to the app
--  - Provide the values for make, model, modelYear, trim parameters from the cache in StartServiceAck to the app
-- 4. App requests RAI
-- SDL does:
--  - Provide systemSoftwareVersion value received from HMI in BC.GetSystemInfo response
--     via RAI response to the app
--  - Provide the values for make, model, modelYear, trim parameters from the cache in RAI response to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local delay1 = 3000
local delay2 = -1
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", common.startWithExtension,
  { delay1, delay2, common.delayedStartServiceAckP5 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
