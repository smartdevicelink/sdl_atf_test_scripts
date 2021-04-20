---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to protected Start RPC Service request over 5th SDL protocol
-- if it contains non existed session id
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. Unprotected RPC service has been started
-- 3. App tries to start protected RPC service over 5th SDL protocol with non existed session id
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3620/common')

--[[ Local Variables ]]
local nonExistedSessionId = 5
local isEncrypted = true
local serviceParams = {
  serviceType = common.serviceType.RPC,
  serviceName = "RPC",
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "5.4.0" }
  },
  nackParams = {
    reason = {
      type = common.bsonType.STRING,
      value = "Cannot start a protected service of type " .. common.serviceType.RPC ..
        ". Session " .. nonExistedSessionId .. " not found for connection 1"
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Start unprotected RPC service", common.startUnprotectedRPCservice)

common.Title("Test")
common.Step("Start protected RPC Service, NACK", common.startServiceNACKwithNonExistedSessionId,
  { serviceParams, nonExistedSessionId, isEncrypted })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
