---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local json = require("modules/json")
local SDL = require("SDL")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local m = {}
local hashId = {}

m.Title = runner.Title
m.Step = runner.Step
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.registerApp = actions.app.register
m.registerAppWOPTU = actions.app.registerNoPTU
m.activateApp = actions.app.activate
m.getMobileSession = actions.mobile.getSession
m.getHMIConnection = actions.hmi.getConnection
m.getAppParams = actions.app.getParams
m.cloneTable = utils.cloneTable
m.start = actions.start
m.postconditions = actions.postconditions
m.policyTableUpdate = actions.policyTableUpdate
m.getAppsCount = actions.mobile.getAppsCount
m.deleteSession = actions.mobile.deleteSession
m.connectMobile = actions.mobile.connect
m.wait = utils.wait
m.spairs = utils.spairs

local handsOffSteeringResponseData = {
  dataType = "VEHICLEDATA_HANDSOFFSTEERING",
  resultCode = "SUCCESS"
}

--[[ Functions ]]
--[[ @updatePreloadedPT: Update preloaded file with additional permissions for handsOffSteering
--! @parameters:
--! pGroup: table with additional updates (optional)
--! @return: none
--]]
local function updatePreloadedPTFile(pGroup)
  local pt = m.getPreloadedPT()
  if not pGroup then
    pGroup = {
      rpcs = {
        GetVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        OnVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        SubscribeVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        },
        UnsubscribeVehicleData = {
          hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
          parameters = { "handsOffSteering" }
        }
      }
    }
  end
  pt.policy_table.functional_groupings["HandsOffSteering"] = pGroup
  pt.policy_table.app_policies["default"].groups = { "Base-4", "HandsOffSteering" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

--[[ @preconditions: Clean environment, optional backup and update of sdl_preloaded_pt.json file
 --! @parameters:
 --! pGroup: data for updating sdl_preloaded_pt.json file
 --! @return: none
 --]]
function m.preconditions(pGroup)
  actions.preconditions()
  updatePreloadedPTFile(pGroup)
end

--[[ @setHashId: Set hashId value which is required during resumption
--! @parameters:
--! pHashValue: application hashId
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.setHashId(pHashValue, pAppId)
  hashId[pAppId] = pHashValue
end

--[[ @getHashId: Get hashId value of an app which is required during resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: app's hashId
--]]
function m.getHashId(pAppId)
  return hashId[pAppId]
end

--[[ @getVehicleData: Successful processing of GetVehicleData RPC
--! @parameters:
--! pHandsOffSteeringHmiValue: value of the handsOffSteering parameter for HMI response
--! @return: none
--]]
function m.getVehicleData(pHandsOffSteeringHmiValue)
  if pHandsOffSteeringHmiValue == nil then pHandsOffSteeringHmiValue = true end
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { handsOffSteering = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { handsOffSteering = pHandsOffSteeringHmiValue })
  end)
  m.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = pHandsOffSteeringHmiValue })
end

--[[ @processRPCFailure: Processing VehicleData RPC with ERROR resultCode
--! @parameters:
--! pRPC: RPC for mobile request
--! pResult: Result code for mobile response
--! pRequestValue: handsOffSteering value for mobile request
--! @return: none
--]]
function m.processRPCFailure(pRPC, pResult, pRequestValue)
  if pRequestValue == nil then pRequestValue = true end
  local cid = m.getMobileSession():SendRPC(pRPC, { handsOffSteering = pRequestValue })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResult })
end

--[[ @processRPCgenericError: Processing VehicleData RPC with invalid HMI response
--! @parameters:
--! pRPC: RPC for mobile request
--! pData: data for HMI response
--! @return: none
--]]
function m.processRPCgenericError(pRPC, pData)
  local cid = m.getMobileSession():SendRPC(pRPC, { handsOffSteering = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { handsOffSteering = true })
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { handsOffSteering = pData })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ @subUnsubScribeVD: Processing SubscribeVehicleData and UnsubscribeVehicleData RPCs
--! @parameters:
--! pRPC: RPC for mobile request
--! pAppId: application number (1, 2, etc.)
--! isRequestOnHMIExpected: true or omitted - in case VehicleInfo.Sub/UnsubscribeVehicleData_request on HMI is expected,
--! otherwise - false
--! @return: none
--]]
function m.processSubscriptionRPC(pRPC, pAppId, isRequestOnHMIExpected)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC(pRPC, { handsOffSteering = true })
  if isRequestOnHMIExpected == nil or isRequestOnHMIExpected == true then
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { handsOffSteering = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { handsOffSteering = handsOffSteeringResponseData })
    end)
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = handsOffSteeringResponseData })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pData: data for the notification
--! pExpTime: number of notifications
--! @return: none
--]]
function m.sendOnVehicleData(pExpTime, pData)
  if not pExpTime then pExpTime = 1 end
  if pData == nil then pData = true end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = pData })
  m.getMobileSession():ExpectNotification("OnVehicleData", { handsOffSteering = pData })
  :Times(pExpTime)
end

--[[ @onVehicleDataTwoApps: Processing OnVehicleData RPC for two apps
--! @parameters:
--! pExpTimes: number of notifications for 2 apps
--! @return: none
--]]
function m.onVehicleDataTwoApps(pExpTimes)
  if pExpTimes == nil then pExpTimes = 1 end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { handsOffSteering = true })
  m.getMobileSession(1):ExpectNotification("OnVehicleData", { handsOffSteering = true })
  :Times(pExpTimes)
  m.getMobileSession(2):ExpectNotification("OnVehicleData", { handsOffSteering = true })
  :Times(pExpTimes)
end

--[[ @ignitionOff: IGNITION_OFF sequence
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  local isOnSDLCloseSent = false
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then m.cprint(35, "BC.OnSDLClose was not sent") end
    StopSDL()
  end)
end

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function m.unexpectedDisconnect()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(m.getAppsCount())
  actions.mobile.disconnect()
  m.wait(1000)
end

--[[ @registerAppWithResumption: Successful application registration with custom expectations for resumption
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! isHMISubscription: if true VD.SubscribeVehicleData request is expected on HMI, otherwise - not expected
--! @return: none
--]]
function m.registerAppWithResumption(pAppId, isHMISubscription)
  if not pAppId then pAppId = 1 end
  local session = actions.mobile.createSession(pAppId)
  session:StartService(7)
  :Do(function()
    m.getAppParams(pAppId).hashID = m.getHashId(pAppId)
    local corId = session:SendRPC("RegisterAppInterface", m.getAppParams(pAppId))
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getAppParams(pAppId).appName }
    })
    if isHMISubscription == true then
      m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { handsOffSteering = true })
      :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { handsOffSteering = handsOffSteeringResponseData })
      end)
    else
      m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData"):Times(0)
    end
    session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      session:ExpectNotification("OnPermissionsChange")
    end)
  end)
end

return m
