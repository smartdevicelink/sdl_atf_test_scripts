---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL does not provide vehicle type data in StartServiceAck for video and audio services
--
-- Steps:
-- 1. HMI provides all vehicle type data in BC.GetSystemInfo(ccpu_version, systemHardwareVersion)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses
-- 2. App is registered via 5th protocol and activated
-- 3. App requests StartService(VIDEO) and StartService(PCM) via 5th protocol
-- SDL does:
--  - Not provide the vehicle type info in StartServiceAck for audio and video services to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

local videoServiceParams = {
  reqParams = {
    height = { type = common.bsonType.INT32,  value = 350 },
    width = { type = common.bsonType.INT32,  value = 800 },
    videoProtocol = { type = common.bsonType.STRING, value = "RAW" },
    videoCodec = { type = common.bsonType.STRING, value = "H264" },
    mtu = { type = common.bsonType.INT64,  value = 131072 }
  }
}

local audioServiceParams = {
  reqParams = {
    mtu = { type = common.bsonType.INT64,  value = 131072 }
  }
}

--[[ Local Functions ]]
local function setVideoConfig()
  common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function startServiceUnprotectedACK(pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtensionFunc)
  common.startServiceUnprotectedACK( pAppId, pServiceId, pRequestPayload, pResponsePayload, pExtensionFunc )
  :ValidIf(function(_, data)
      local actPayload = common.bson_to_table(data.binaryData)
      if false == common.isTableEqual(actPayload, pResponsePayload) then
        return false, "BinaryData are not match to expected result.\n" ..
          "Actual result:" .. common.tableToString(actPayload) .. "\n" ..
          "Expected result:" ..common.tableToString(pResponsePayload) .."\n"
      end
      return true
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Register App", common.registerAppUpdatedProtocolVersion)
common.Step("Activate App", common.activateApp)
common.Step("Start unprotected Video Service, ACK", startServiceUnprotectedACK,
  { 1, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.reqParams, setVideoConfig })
common.Step("Start unprotected Audio Service, ACK", startServiceUnprotectedACK,
  { 1, common.serviceType.PCM, audioServiceParams.reqParams, audioServiceParams.reqParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
