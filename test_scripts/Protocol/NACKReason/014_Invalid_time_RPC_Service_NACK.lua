---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md
--
-- Description: SDL provides reason information in NACK message
-- in case NACK received because system time is not provided during service starting
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is activated
--
-- Steps:
-- 1. Mobile app requests the opening of protected RPC service
-- 2. SDL requests system time via BC.GetSystemTime request
-- 3. HMI responds with DATA_NOT_AVAILABLE resultCode
-- SDL does:
-- - respond with NACK to StartService request because system time is not provided
-- - provide reason information in NACK message
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local isPTUtriggered = true
local rpcServiceParams = {
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "5.3.0" }
  },
  nackParams = {
    reason = { type = common.bsonType.STRING, value = "Failed to get system time" }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("ForceProtectedService = 0x0A, 0x0B", common.sdl.setSDLIniParameter,
  { "ForceProtectedService", "0x0A, 0x0B" })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppUpdatedProtocolVersion, { isPTUtriggered })
common.Step("PTU", common.policyTableUpdate)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Start RPC Service, system time is not provided, NACK", common.startSecureServiceTimeNotProvided,
  { 1, common.serviceType.RPC, rpcServiceParams.reqParams, rpcServiceParams.nackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
