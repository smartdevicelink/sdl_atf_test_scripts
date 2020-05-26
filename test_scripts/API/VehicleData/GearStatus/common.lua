---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local json = require("modules/json")
local utils = require("user_modules/utils")
local SDL = require("SDL")
local runner = require('user_modules/script_runner')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Variables ]]
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
m.restorePreloadedPT = actions.sdl.restorePreloadedPT
m.cloneTable = utils.cloneTable
m.getConfigAppParams = actions.getConfigAppParams
m.start = actions.start
m.policyTableUpdate = actions.policyTableUpdate
m.getAppsCount = actions.mobile.getAppsCount
m.getAppParams = actions.app.getParams
m.deleteSession = actions.mobile.deleteSession
m.connectMobile = actions.mobile.connect
m.wait = utils.wait
m.postconditions = actions.postconditions
m.spairs = utils.spairs
m.appUnregistration = actions.app.unRegister

local gearStatusData = {
  userSelectedGear = "NINTH",
  actualGear = "TENTH",
  transmissionType = "MANUAL"
}

local gearStatusSubscriptionResponse = {
  dataType = "VEHICLEDATA_GEARSTATUS",
  resultCode = "SUCCESS"
}

local prndlSubscriptionResponse = {
  dataType = "VEHICLEDATA_PRNDL",
  resultCode = "SUCCESS"
}

m.prndlEnumValues = {
  "PARK",
  "REVERSE",
  "NEUTRAL",
  "DRIVE",
  "SPORT",
  "LOWGEAR",
  "FIRST",
  "SECOND",
  "THIRD",
  "FOURTH",
  "FIFTH",
  "SIXTH",
  "SEVENTH",
  "EIGHTH",
  "NINTH",
  "TENTH",
  "UNKNOWN",
  "FAULT"
}

m.transmissionTypeValues = {
  "MANUAL",
  "AUTOMATIC",
  "SEMI_AUTOMATIC",
  "DUAL_CLUTCH",
  "CONTINUOUSLY_VARIABLE",
  "INFINITELY_VARIABLE",
  "ELECTRIC_VARIABLE",
  "DIRECT_DRIVE"
}

--[[ Common Functions ]]

--[[ @updatePreloadedPT: Update preloaded file with additional permissions for GearStatus
--! @parameters:
--! pGroup: table with additional updates (optional)
--! @return: none
--]]
function m.updatePreloadedPT(pGroup)
  local pt = m.getPreloadedPT()
  if pGroup == nil then
    pGroup = {
      rpcs = {
        GetVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
          parameters = { "gearStatus" }
        },
        OnVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
          parameters = { "gearStatus" }
        },
        SubscribeVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
          parameters = { "gearStatus"}
        },
        UnsubscribeVehicleData = {
          hmi_levels = { "BACKGROUND", "LIMITED", "FULL", "NONE" },
          parameters = { "gearStatus" }
        }
      }
    }
  end
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroup
  pt.policy_table.app_policies["default"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  m.setPreloadedPT(pt)
end

--[[ @preconditions: Clean environment, optional backup and update of sdl_preloaded_pt.json file
--! @parameters:
--! isPreloadedUpdate: if omitted or true then sdl_preloaded_pt.json file will be updated, otherwise - false
--! pGroup: table with additional updates for preloaded file
--! @return: none
--]]
function m.preconditions(isPreloadedUpdate, pGroup)
  actions.preconditions()
  if isPreloadedUpdate == true or isPreloadedUpdate == nil then
    m.updatePreloadedPT(pGroup)
  end
end

--! @pTUpdateFunc: Policy Table Update with allowed "Base-4" and custom group for application
--! @parameters:
--! tbl: policy table
--! @return: none
function m.pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      UnsubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      },
      OnVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      }
    }
  }
  tbl.policy_table.functional_groupings.NewVehicleDataGroup = VDgroup
  tbl.policy_table.app_policies[m.getAppParams().fullAppID].groups = { "Base-4", "NewVehicleDataGroup" }
end

--[[ @setHashId: Set hashId value which is required during resumption
--! @parameters:
--! pHashValue: application's hashId
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

--[[ @checkParam: Check the absence of unexpected parameters
--! @parameters:
--! pDataActual - actual received = data to check
--! pDataExpected - expected data
--! pRPC - RPC name
--! @return: true - in case a message contains expected parameters number, otherwise - false with error message
--]]
local function checkParam(pDataActual, pDataExpected, pRPC)
  local result = utils.isTableEqual(pDataActual, pDataExpected)
  if result == false then
    return false, "Unexpected parameters are received in " .. pRPC
  else
    return true
  end
end

--[[ @getGearStatusParams: Clone table with gearStatus data for using in GetVD and OnVD RPCs
--! @parameters: none
--! @return: table for GetVD and OnVD
--]]
function m.getGearStatusParams()
  return utils.cloneTable(gearStatusData)
end

--[[ @getGearStatusSubscriptionResData: Clone table with data for using in SubscribeVD and UnsubscribeVD RPCs
--! @parameters: none
--! @return: table for SubscribeVD and UnsubscribeVD
--]]
function m.getGearStatusSubscriptionResData()
  return utils.cloneTable(gearStatusSubscriptionResponse)
end

--[[ @getCustomData: Set value for params from `gearStatus` structure
--! @parameters:
--! pParam: parameters from `gearStatus` structure
--! pValue: value for parameters from the `gearStatus` structure
--! @return: table for GetVD and OnVD
--]]
function m.getCustomData(pParam, pValue)
  local param = m.getGearStatusParams()
  param[pParam] = pValue
  return param
end

--[[ @getVehicleData: Successful processing of GetVehicleData RPC
--! @parameters:
--! pData: data for GetVehicleData response
--! pParam: parameter for GetVehicleData request
--! @return: none
--]]
function m.getVehicleData(pData, pParam)
  if not pParam then pParam = "gearStatus" end
  if not pData then pData = m.getGearStatusParams() end
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { [pParam] = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { [pParam] = true })
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = pData })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [pParam] = pData })
  :ValidIf(function(_, data)
    return checkParam(data.payload[pParam], pData, "GetVehicleData")
  end)
end

--[[ @processRPCFailure: Processing VehicleData RPC with ERROR resultCode
--! @parameters:
--! pRPC: RPC for mobile request
--! pResult: Result code for mobile response
--! pValue: gearStatus value for mobile request
--! @return: none
--]]
function m.processRPCFailure(pRPC, pResult, pValue)
  if not pValue then pValue = true end
  local cid = m.getMobileSession():SendRPC(pRPC, { gearStatus = pValue })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResult })
end

--[[ @invalidDataFromHMI: Processing VehicleData RPC with invalid HMI response
--! @parameters:
--! pRPC: RPC for mobile request
--! pData: data for HMI response
--! @return: none
--]]
function m.invalidDataFromHMI(pRPC, pData)
  local cid = m.getMobileSession():SendRPC(pRPC, { gearStatus = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." ..pRPC, { gearStatus = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gearStatus = pData })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ @processSubscriptionRPC: Processing Subscribe/UnsubscribeVehicleData RPC
--! @parameters:
--! pRPC: RPC for mobile request
--! pAppId: application number (1, 2, etc.)
--! isRequestOnHMIExpected: true or omitted - in case VehicleInfo.Subscribe/UnsubscribeVehicleData request is expected
--!  on HMI, otherwise - not expected
--! pParam: parameters for Subscribe/UnsubscribeVehicleData RPC
--! @return: none
--]]
function m.processSubscriptionRPC(pRPC, pAppId, isRequestOnHMIExpected, pParam)
  local responseData
  if not pParam then pParam = "gearStatus" end
  if pParam == "gearStatus" then responseData = m.getGearStatusSubscriptionResData()
  else
     responseData = prndlSubscriptionResponse
  end
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC(pRPC, { [pParam] = true })
  if isRequestOnHMIExpected == nil or isRequestOnHMIExpected == true then
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { [pParam] = true })
    :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = responseData })
    end)
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS", [pParam] = responseData })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
end

--[[ @sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pData: data for the notification
--! pExpTime: expected number of notifications
--! pParam: parameter for OnVehicleData RPC
--! @return: none
--]]
function m.sendOnVehicleData(pData, pExpTime, pParam)
  if not pExpTime then pExpTime = 1 end
  if not pParam then pParam = "gearStatus" end
  if not pData then pData = m.getGearStatusParams() end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { [pParam] = pData })
  m.getMobileSession():ExpectNotification("OnVehicleData", { [pParam] = pData })
  :ValidIf(function(_, data)
    return checkParam(data.payload[pParam], pData, "OnVehicleData")
  end)
  :Times(pExpTime)
end

--[[ @onVehicleDataTwoApps: Processing OnVehicleData RPC for two apps
--! @parameters:
--! pExpTimes: number of notifications for 2 apps
--! @return: none
--]]
function m.onVehicleDataTwoApps(pExpTimes)
  if pExpTimes == nil then pExpTimes = 1 end
  local params = m.getGearStatusParams()
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gearStatus = params })
  m.getMobileSession(1):ExpectNotification("OnVehicleData", { gearStatus = params })
  :Times(pExpTimes)
  m.getMobileSession(2):ExpectNotification("OnVehicleData", { gearStatus = params })
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

--[[ @registerAppWithResumption:  Successful application registration with custom expectations for resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! isHMIsubscription: if true VD.SubscribeVehicleData request is expected on HMI, otherwise - not expected
--! @return: none
--]]
function m.registerAppWithResumption(pAppId, isHMIsubscription)
  if not pAppId then pAppId = 1 end
  local session = actions.mobile.createSession(pAppId)
  session:StartService(7)
  :Do(function()
    m.getConfigAppParams(pAppId).hashID = m.getHashId(pAppId)
    local corId = session:SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getConfigAppParams(pAppId).appName }
    })
    :Do(function()
      if true == isHMIsubscription then
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData", { gearStatus = true })
        :Do(function(_, data)
          m.getHMIConnection():SendResponse( data.id, data.method, "SUCCESS",
            { gearStatus = m.getGearStatusSubscriptionResData() } )
        end)
      else
        m.getHMIConnection():ExpectRequest( "VehicleInfo.SubscribeVehicleData"):Times(0)
      end
    end)
    session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      session:ExpectNotification("OnPermissionsChange")
    end)
  end)
end

return m
