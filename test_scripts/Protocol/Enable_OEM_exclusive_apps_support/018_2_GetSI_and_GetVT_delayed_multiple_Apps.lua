---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide vehicle type data for each app that requests StartService and
--  RAI via 5 protocol after all vehicle type data have been received in case StartService is requested before receiving
--  BC.GetSystemInfo and VI.GetVehicleType responses
--
-- Steps:
-- 1. SDL requests BC.GetSystemInfo and VI.GetVehicleType to HMI after start
-- 2. App1 and App2 request StartService(RPC) via 5th protocol
-- SDL does:
--  - Postpone the sending of StartServiceAcks before receiving of BC.GetSystemInfo and VI.GetVehicleType responses
-- 3. HMI responds with delay to BC.GetSystemInfo and to VI.GetVehicleType requests
-- SDL does:
--  - Send StartServiceAcks after receiving VI.GetVehicleType and BC.GetSystemInfo responses with the vehicle type info
--     with all parameter values received from HMI to app1 and app2
-- 4. App1 and App2 request RAI after receiving StartServiceAck
-- SDL does:
--  - Provide the vehicle type info with all parameter values received from HMI except systemHardwareVersion in
--   RAI response to the app1 and app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local delay1 = 2000
local delay2 = 3000

--[[ Local Functions ]]
local function delayedStartServiceAckMultipleApps(_, pTS, pRpcServiceAckParams)
  local reqParams = { protocolVersion = common.setStringBsonValue("5.4.0") }
  local mobSession1 = common.createSession(1)
  local mobSession2 = common.createSession(2)
  local msg = {
    serviceType = common.serviceType.RPC,
    frameType = common.frameType.CONTROL_FRAME,
    frameInfo = common.frameInfo.START_SERVICE,
    encryption = false,
    binaryData = common.bson_to_bytes(reqParams)
  }

  mobSession1:Send(msg)
  common.log("MOB->SDL: App1".." StartService(7)", reqParams)

  mobSession2:Send(msg)
  common.log("MOB->SDL: App2" .." StartService(7)", reqParams)

  local function validateResponse(pData)
    local actPayload = common.bson_to_table(pData.binaryData)
    common.log("SDL->MOB: App" ..pData.sessionId.." StartServiceAck(7)", actPayload)
    if pTS.ts_get_si == nil then
      return false, "StartServiceAck received before receiving of GetSystemInfo from HMI"
    end
    if pTS.ts_get_vt == nil then
      return false, "StartServiceAck received before receiving of GetVehicleType from HMI"
    end
    return compareValues(pRpcServiceAckParams, actPayload, "binaryData")
  end

  common.getMobileSession():ExpectControlMessage(common.serviceType.RPC, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = false
  })
  :ValidIf(function(exp, data)
      if exp.occurences == 1 and data.frameInfo == common.frameInfo.START_SERVICE_ACK then
          mobSession1.sessionId = data.sessionId
          return validateResponse(data)
      elseif exp.occurences == 2 and data.frameInfo == common.frameInfo.START_SERVICE_ACK then
          mobSession2.sessionId = data.sessionId
          return validateResponse(data)
      end
      return false, "Unexpected message have been received"
    end)
  :Times(2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL, HMI, connect Mobile, start Session, send StartService", common.startWithExtension,
  { delay1, delay2, delayedStartServiceAckMultipleApps })
common.Step("Vehicle type data in RAI App1", common.registerAppEx,
  { common.vehicleTypeInfoParams.default, appSessionId1 })
common.Step("Vehicle type data in RAI App2", common.registerAppEx,
  { common.vehicleTypeInfoParams.default, appSessionId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
