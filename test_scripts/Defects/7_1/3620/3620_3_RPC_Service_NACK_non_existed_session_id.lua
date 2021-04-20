---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to Start RPC Service request over 5th SDL protocol
-- if it contains non existed session id
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. App tries to start RPC service over 5th SDL protocol with non existed session id
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3620/common')

--[[ Local Variables ]]
local nonExistedSessionId = 5
local serviceParams = {
  serviceType = common.serviceType.RPC,
  serviceName = "RPC",
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "5.4.0" }
  },
  nackParams = {
    reason = {
      type = common.bsonType.STRING,
      value = "Cannot start an unprotected service of type " .. common.serviceType.RPC ..
        ". Session " .. nonExistedSessionId .. " not found for connection 1"
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.Title("Test")
common.Step("Start RPC Service, NACK", common.startServiceNACKwithNonExistedSessionId,
  { serviceParams, nonExistedSessionId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
