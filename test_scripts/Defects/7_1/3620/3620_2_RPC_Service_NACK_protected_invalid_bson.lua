---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to protected Start RPC Service request over 5th SDL protocol
-- if it contains invalid data in bson payload
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. Unprotected RPC service has been started
-- 3. App tries to start protected RPC service over 5th SDL protocol with invalid data in bson payload
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3620/common')

--[[ Local Variables ]]
local serviceParams = {
  serviceType = common.serviceType.RPC,
  serviceName = "RPC",
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "invalid_value" } -- invalid value
  },
  nackParams = {
    rejectedParams = {
      type = common.bsonType.ARRAY,
      value = {
        [1] = { type = common.bsonType.STRING, value = "protocolVersion" }
      }
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Start unprotected RPC service", common.startUnprotectedRPCservice)

common.Title("Test")
common.Step("Start protected RPC Service, NACK", common.startProtectedServiceWithOnServiceUpdate, { serviceParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
