---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")
local constants = require("protocol_handler/ford_protocol_constants")

--[[ General configuration parameters ]]
common.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5

--[[ Common Variables ]]
common.SERVICE_TYPE = constants.SERVICE_TYPE
common.FRAME_TYPE = constants.FRAME_TYPE
common.FRAME_INFO = constants.FRAME_INFO

--[[ Common Functions ]]
function common.startServiceNACKwithNonExistedSessionId(pServiceParams, pNonExistedSessionId, isEncrypted)
  isEncrypted = isEncrypted or false
  local mobSession = common.getMobileSession()
  mobSession.sessionId = pNonExistedSessionId
  local msg = {
    serviceType = pServiceParams.serviceType,
    frameType = common.FRAME_TYPE.CONTROL_FRAME,
    frameInfo = common.FRAME_INFO.START_SERVICE,
    encryption = isEncrypted,
    binaryData = common.bson_to_bytes(pServiceParams.reqParams)
  }
  mobSession:Send(msg)
  mobSession:ExpectControlMessage(pServiceParams.serviceType, {
    frameInfo = common.FRAME_INFO.START_SERVICE_NACK,
    encryption = false
  })
  :ValidIf(function(_, data)
      local act = common.bson_to_table(data.binaryData)
      return compareValues(pServiceParams.nackParams, act, "binaryData")
    end)
  :Timeout(1000)
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceParams.serviceName},
    { serviceEvent = "REQUEST_REJECTED", serviceType = pServiceParams.serviceName })
  :Times(2)
end

function common.startUnprotectedRPCservice()
  local session = common.getMobileSession()
  local msg = {
    serviceType = common.serviceType.RPC,
    frameType = constants.FRAME_TYPE.CONTROL_FRAME,
    frameInfo = constants.FRAME_INFO.START_SERVICE,
    encryption = false,
    binaryData = common.bson_to_bytes({ protocolVersion = { type = common.bsonType.STRING, value = "5.4.0" }})
  }
  session:Send(msg)

  session:ExpectControlMessage(common.serviceType.RPC, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = false
  })
end

function common.startProtectedServiceWithOnServiceUpdate(pServiceParams)
  local appId = 1
  common.startServiceProtectedNACK(appId, pServiceParams.serviceType, pServiceParams.reqParams,
    pServiceParams.nackParams)
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceParams.serviceName },
    { serviceEvent = "REQUEST_REJECTED", serviceType = pServiceParams.serviceName })
  :Times(2)
end

function common.startWithoutOnSystemTimeReady(pHMIParams)
  local event = common.run.createEvent()
  common.init.SDL()
  :Do(function()
      common.init.HMI()
      :Do(function()
        common.init.HMI_onReady(pHMIParams)
          :Do(function()
              common.init.connectMobile()
              :Do(function()
                  common.init.allowSDL()
                  :Do(function()
                      common.hmi.getConnection():RaiseEvent(event, "Start event")
                    end)
                end)
            end)
        end)
    end)
  return common.hmi.getConnection():ExpectEvent(event, "Start event")
end

return common
