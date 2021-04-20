---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonRC = require('test_scripts/RC/commonRC')
local utils = require("user_modules/utils")
local functionId = require('function_id')

--[[ Module ]]
commonRC.tableToString = utils.tableToString
commonRC.isTableEqual = utils.isTableEqual
commonRC.wait = utils.wait

config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.isMediaApplication = false

commonRC.modules = { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }
commonRC.functionId = functionId

function commonRC.GetInteriorVehicleData(pModuleType, isSubscribe, isHMIreqExpect, pAppId, pResultCode)
  if not pAppId then pAppId = 1 end
  local rpc = "GetInteriorVehicleData"
  local HMIrequestsNumber
  if isHMIreqExpect == true then
	  HMIrequestsNumber = 1
  else
	  HMIrequestsNumber = 0
  end
  local cid = commonRC.getMobileSession(pAppId):SendRPC(commonRC.getAppEventName(rpc),
    commonRC.getAppRequestParams(rpc, pModuleType, isSubscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, isSubscribe))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      commonRC.getHMIResponseParams(rpc, pModuleType, isSubscribe))
    end)
  :Times(HMIrequestsNumber)
  local resultCode = pResultCode or "SUCCESS"
  commonRC.getMobileSession(pAppId):ExpectResponse(cid, commonRC.getAppResponseParams(rpc, true, resultCode, pModuleType, isSubscribe))
end

function commonRC.GetInteriorVehicleDataRejected(pModuleType, isSubscribe, pAppId)
  if not pAppId then pAppId = 1 end
  local rpc = "GetInteriorVehicleData"
  local subscribe = isSubscribe
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(rpc),
    commonRC.getAppRequestParams(rpc, pModuleType, subscribe))
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc))
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED"})
end

function commonRC.OnInteriorVD(pModuleType, isExpectNotification, pAppId, pParams)
  local rpc = "OnInteriorVehicleData"
  local mobSession = commonRC.getMobileSession(pAppId)
  if not pParams then pParams = commonRC.moduleDataUpdate(pModuleType) end
  local notificationCount
  if isExpectNotification == true then
    notificationCount = 1
  else
    notificationCount = 0
  end
  commonRC.setActualInteriorVD(pModuleType, pParams)
  commonRC.getHMIConnection():SendNotification(commonRC.getHMIEventName(rpc), {moduleData = pParams})
  mobSession:ExpectNotification(commonRC.getAppEventName(rpc), {moduleData = pParams})
  :Times(notificationCount)
end

function commonRC.unregistrationApp(pAppId, isHMIreqExpect, pModuleType)
  local rpc = "GetInteriorVehicleData"
  local HMIrequestsNumber
  if isHMIreqExpect == true then
    HMIrequestsNumber = 1
  else
    HMIrequestsNumber = 0
  end
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, false))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      commonRC.getHMIResponseParams(rpc, pModuleType, false))
    end)
  :Times(HMIrequestsNumber)
  local cid = commonRC.getMobileSession(pAppId):SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = commonRC.getHMIAppId(pAppId), unexpectedDisconnect = false })
  commonRC.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function commonRC.setGetInteriorVehicleDataRequestValue(pValue)
  actions.setSDLIniParameter("GetInteriorVehicleDataRequest", pValue)
  commonRC.wait(1000)
end

function commonRC.unexpectedDisconnect(pAppId, isHMIreqExpect, pModuleType)
  local rpc = "GetInteriorVehicleData"
  local HMIrequestsNumber
  if isHMIreqExpect == true then
    HMIrequestsNumber = 1
  else
    HMIrequestsNumber = 0
  end
  EXPECT_HMICALL(commonRC.getHMIEventName(rpc), commonRC.getHMIRequestParams(rpc, pModuleType, pAppId, false))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      commonRC.getHMIResponseParams(rpc, pModuleType, false))
    end)
  :Times(HMIrequestsNumber)
  commonRC.getMobileSession(pAppId):Stop()
  commonRC.wait(1000)
end

function commonRC.moduleDataUpdate(pModuleType)
  local params = commonRC.cloneTable(commonRC.actualInteriorDataStateOnHMI[pModuleType])
  for key, value in pairs(params) do
    if type(value) == "boolean" then
      if value == true then
        params[key] = false
      else
        params[key] = true
      end
    end
  end
  return params
end

return commonRC
