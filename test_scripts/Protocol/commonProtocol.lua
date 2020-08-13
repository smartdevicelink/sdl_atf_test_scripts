---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local ssl = require("test_scripts/Security/SSLHandshakeFlow/common")
local constants = require("protocol_handler/ford_protocol_constants")
local utils = require('user_modules/utils')
local events = require("events")
local bson = require('bson4lua')
  
--[[ General configuration parameters ]]

--[[ Variables ]]
local common = ssl

common.events      = events
common.frameInfo   = constants.FRAME_INFO
common.frameType   = constants.FRAME_TYPE
common.serviceType = constants.SERVICE_TYPE
common.getDeviceName = utils.getDeviceName
common.getDeviceMAC = utils.getDeviceMAC

common.bsonType = {
    DOUBLE   = 0x01,
    STRING   = 0x02,
    DOCUMENT = 0x03,
    ARRAY    = 0x04,
    BOOLEAN  = 0x08,
    INT32    = 0x10,
    INT64    = 0x12
}

--[[ Functions ]]
function common.startServiceProtectedACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartSecureService(pServiceId, bson.to_bytes(pRequestPayload))
    mobSession:ExpectControlMessage(pServiceId, {
      frameInfo = common.frameInfo.START_SERVICE_ACK,
      encryption = true
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
    
    if pServiceId == 7 then
        mobSession:ExpectHandshakeMessage()
    elseif pServiceId == 11 then
        common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
        :Do(function(_, data)
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
end
  
function common.startServiceUnprotectedACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartService(pServiceId, bson.to_bytes(pRequestPayload))
    mobSession:ExpectControlMessage(pServiceId, {
      frameInfo = common.frameInfo.START_SERVICE_ACK,
      encryption = false
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
end

function common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartSecureService(pServiceId, bson.to_bytes(pRequestPayload))
    mobSession:ExpectControlMessage(pServiceId, {
        frameInfo = common.frameInfo.START_SERVICE_NACK,
        encryption = false
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
end


function common.startServiceUnprotectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
    local mobSession = common.getMobileSession(pAppId)
    mobSession:StartService(pServiceId, bson.to_bytes(pRequestPayload))
    mobSession:ExpectControlMessage(pServiceId, {
        frameInfo = common.frameInfo.START_SERVICE_NACK,
        encryption = false
    })
    :ValidIf(function(_, data)
        local actPayload = bson.to_table(data.binaryData)
        return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
end

return common
