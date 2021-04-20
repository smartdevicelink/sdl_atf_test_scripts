---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md
--
-- Description: SDL provides reason information in NACK message
-- in case NACK received because PTU is failed during service starting
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is activated
--
-- Steps:
-- 1. Mobile app requests the opening of protected Audio service
-- 2. PTU is triggered to get actual certificate
-- 3. Mobile app provides invalid update in SystemRequest
-- SDL does:
-- - respond with NACK to StartService request because PTU is failed
-- - provide reason information in NACK message
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local isPTUtriggered = true
local audioServiceParams = {
  reqParams = {
    mtu = { type = common.bsonType.INT64,  value = 131072 }
  },
  nackParams = {
    reason = { type = common.bsonType.STRING, value = "Policy Table Update failed" }
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
common.Step("Start Audio Service, PTU failed, NACK", common.ptuFailedNACK,
  { 1, common.serviceType.PCM, audioServiceParams.reqParams, audioServiceParams.nackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
