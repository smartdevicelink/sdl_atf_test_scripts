---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3620
---------------------------------------------------------------------------------------------------
-- Description: Check SDL responds with NACK to Start RPC Service request over 5th SDL protocol
-- if it contains invalid data in bson payload
--
-- Steps:
-- 1. Start SDL, HMI, connect mobile device
-- 2. App tries to start RPC service over 5th SDL protocol with invalid data in bson payload
-- SDL does:
--  - send 'OnServiceUpdate' notification to HMI with 'REQUEST_REJECTED'
--  - respond with NACK to start service request
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_1/3620/common')

--[[ Local Variables ]]
local appId = 1
local serviceParams = {
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

--[[ Local Functions ]]
local function onServiceUpdateExp()
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = "RPC" },
    { serviceEvent = "REQUEST_REJECTED", serviceType = "RPC" })
  :Times(2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.Title("Test")
common.Step("Start RPC Service, NACK", common.startServiceUnprotectedNACK,
  { appId, common.serviceType.RPC, serviceParams.reqParams, serviceParams.nackParams, onServiceUpdateExp })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
