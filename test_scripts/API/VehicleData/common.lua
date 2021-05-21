---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local json = require("modules/json")
local SDL = require("SDL")
local color = require("user_modules/consts").color
local api = require("user_modules/api/APIHelper")
local gen = require("user_modules/api/APITestDataGenerator")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2
config.zeroOccurrenceTimeout = 1000

--[[ Module ]]
local m = {}

--[[ Common Proxy Functions ]]
do
  m.runner = runner
  m.getPreloadedPT = actions.sdl.getPreloadedPT
  m.setPreloadedPT = actions.sdl.setPreloadedPT
  m.registerApp = actions.app.register
  m.registerAppWOPTU = actions.app.registerNoPTU
  m.activateApp = actions.app.activate
  m.getMobileSession = actions.getMobileSession
  m.getHMIConnection = actions.hmi.getConnection
  m.getAppParams = actions.app.getParams
  m.getConfigAppParams = actions.app.getParams
  m.cloneTable = utils.cloneTable
  m.start = actions.start
  m.postconditions = actions.postconditions
  m.policyTableUpdate = actions.policyTableUpdate
  m.connectMobile = actions.mobile.connect
  m.wait = utils.wait
  m.spairs = utils.spairs
  m.cprint = utils.cprint
  m.json = actions.json
end

--[[ Common Constants and Variables ]]
m.rpc = {
  get = "GetVehicleData",
  sub = "SubscribeVehicleData",
  unsub = "UnsubscribeVehicleData",
  on = "OnVehicleData"
}

m.rpcHMIMap = {
  [m.rpc.get] = "VehicleInfo.GetVehicleData",
  [m.rpc.sub] = "VehicleInfo.SubscribeVehicleData",
  [m.rpc.unsub] = "VehicleInfo.UnsubscribeVehicleData",
  [m.rpc.on] = "VehicleInfo.OnVehicleData"
}

m.vd = {
  vin = "",
  gps = "VEHICLEDATA_GPS",
  speed = "VEHICLEDATA_SPEED",
  rpm = "VEHICLEDATA_RPM",
  fuelLevel = "VEHICLEDATA_FUELLEVEL",
  fuelLevel_State = "VEHICLEDATA_FUELLEVEL_STATE",
  instantFuelConsumption = "VEHICLEDATA_FUELCONSUMPTION",
  externalTemperature = "VEHICLEDATA_EXTERNTEMP",
  prndl = "VEHICLEDATA_PRNDL",
  tirePressure = "VEHICLEDATA_TIREPRESSURE",
  odometer = "VEHICLEDATA_ODOMETER",
  beltStatus = "VEHICLEDATA_BELTSTATUS",
  bodyInformation = "VEHICLEDATA_BODYINFO",
  deviceStatus = "VEHICLEDATA_DEVICESTATUS",
  eCallInfo = "VEHICLEDATA_ECALLINFO",
  airbagStatus = "VEHICLEDATA_AIRBAGSTATUS",
  emergencyEvent = "VEHICLEDATA_EMERGENCYEVENT",
  -- clusterModeStatus = "VEHICLEDATA_CLUSTERMODESTATUS", -- disabled due to issue: https://github.com/smartdevicelink/sdl_core/issues/3460
  myKey = "VEHICLEDATA_MYKEY",
  driverBraking = "VEHICLEDATA_BRAKING",
  wiperStatus = "VEHICLEDATA_WIPERSTATUS",
  headLampStatus = "VEHICLEDATA_HEADLAMPSTATUS",
  engineTorque = "VEHICLEDATA_ENGINETORQUE",
  accPedalPosition = "VEHICLEDATA_ACCPEDAL",
  steeringWheelAngle = "VEHICLEDATA_STEERINGWHEEL",
  turnSignal = "VEHICLEDATA_TURNSIGNAL",
  fuelRange = "VEHICLEDATA_FUELRANGE",
  engineOilLife = "VEHICLEDATA_ENGINEOILLIFE",
  electronicParkBrakeStatus = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS",
  cloudAppVehicleID = "VEHICLEDATA_CLOUDAPPVEHICLEID",
  handsOffSteering = "VEHICLEDATA_HANDSOFFSTEERING",
  stabilityControlsStatus = "VEHICLEDATA_STABILITYCONTROLSSTATUS",
  gearStatus = "VEHICLEDATA_GEARSTATUS",
  windowStatus = "VEHICLEDATA_WINDOWSTATUS",
  seatOccupancy = "VEHICLEDATA_SEATOCCUPANCY",
  climateData = "VEHICLEDATA_CLIMATEDATA"
}

m.operator = {
  increase = 1,
  decrease = -1
}

m.app = {
  [1] = 1,
  [2] = 2
}

m.isExpected = 1
m.isNotExpected = 0
m.isExpectedSubscription = true
m.isNotExpectedSubscription = false

m.testType = {
  VALID_RANDOM_ALL = 1,   -- Positive: cases for VD parameters where all possible sub-parameters of hierarchy
                          -- are defined with valid random values
  VALID_RANDOM_SUB = 2,   -- Positive: cases for struct VD parameters and sub-parameters where only one sub-parameter
                          -- of hierarchy is defined with valid random value (mandatory also included)
  LOWER_IN_BOUND = 3,     -- Positive: cases for VD parameters and sub-parameters where only one sub-parameter
                          -- of hierarchy is defined with min valid value (mandatory also included)
  UPPER_IN_BOUND = 4,     -- Positive: cases for VD parameters and sub-parameters where only one sub-parameter
                          -- of hierarchy is defined with max valid value (mandatory also included)
  LOWER_OUT_OF_BOUND = 5, -- Negative: cases for VD parameters and sub-parameters where only one sub-parameter
                          -- of hierarchy is defined with nearest invalid min value
  UPPER_OUT_OF_BOUND = 6, -- Negative: cases for VD parameters and sub-parameters where only one sub-parameter
                          -- of hierarchy is defined with nearest invalid max value
  INVALID_TYPE = 7,       -- Negative: cases for VD parameters and sub-parameters with invalid type value defined
                          -- for one of them
  ENUM_ITEMS = 8,         -- Positive: cases for enum VD parameters and sub-parameters with all possible enum values
                          -- defined
  BOOL_ITEMS = 9,         -- Positive: cases for boolean VD parameters and sub-parameters with 'true' and 'false'
                          -- values defined
  PARAM_VERSION = 10,     -- Positive/Negative: cases for VD parameters with version defined
                          --
  MANDATORY_ONLY = 11,    -- Positive: cases for struct VD parameters and sub-parameters
                          -- where only mandatory sub-parameters are defined with valid random values
  MANDATORY_MISSING = 12  -- Negative: cases for struct VD parameters and sub-parameters
                          -- where only mandatory sub-parameters are defined and one of them is missing
}

m.isMandatory = {
  YES = true, -- only mandatory
  NO = false, -- only optional
  ALL = 3     -- both mandatory and optional
}

m.isArray = {
  YES = true, -- only array
  NO = false, -- only non-array
  ALL = 3     -- both array and non-array
}

m.isVersion = {
  YES = true, -- only with version
  NO = false, -- only without version
  ALL = 3     -- both with and without version
}

--[[ Local Constants and Variables ]]
local hashId = {}
local isSubscribed = {}
local rpc
local rpcType
local testType
local paramName
local boundValueTypeMap = {
  [m.testType.UPPER_IN_BOUND] = gen.valueType.UPPER_IN_BOUND,
  [m.testType.LOWER_IN_BOUND] = gen.valueType.LOWER_IN_BOUND,
  [m.testType.UPPER_OUT_OF_BOUND] = gen.valueType.UPPER_OUT_OF_BOUND,
  [m.testType.LOWER_OUT_OF_BOUND] = gen.valueType.LOWER_OUT_OF_BOUND
}
local isRestricted = false

--[[ Common Functions ]]

--[[ @restrictAvailableVDParams: Restrict VD parameters for test by only ones defined in 'VD_PARAMS' environment variable
--! @parameters: none
--! @return: table with restrict VD parameters
--]]
local function restrictAvailableVDParams()
  local extVDParams = os.getenv("VD_PARAMS")
  local checkedExtVDParams = {}
  if extVDParams ~= nil then
    m.cprint(color.magenta, "Environment variable 'VD_PARAMS': " .. extVDParams)
    for _, p in pairs(utils.splitString(extVDParams, ",")) do
      if m.vd[p] ~= nil then
        isRestricted = true
        table.insert(checkedExtVDParams, p)
      else
        m.cprint(color.magenta, "Unknown VD parameter:", p)
      end
    end
  end
  if #checkedExtVDParams > 0 then
    for k in pairs(m.vd) do
      if not utils.isTableContains(checkedExtVDParams, k) then
        m.vd[k] = nil
      end
    end
    local checkedExtVDParamsToPrint = ""
    for id, p in pairs(checkedExtVDParams) do
      checkedExtVDParamsToPrint = checkedExtVDParamsToPrint .. p
      if id ~= #checkedExtVDParams then checkedExtVDParamsToPrint = checkedExtVDParamsToPrint .. ", " end
    end
    m.cprint(color.magenta, "Testing VD parameters restricted to: " .. checkedExtVDParamsToPrint)
  else
    m.cprint(color.magenta, "Testing VD parameters are not restricted")
  end
  return checkedExtVDParams
end

m.restrictedVDParams = restrictAvailableVDParams()

--[[ @getAvailableVDParams: Return VD parameters available for processing
--! @parameters: none
--! @return: table with VD parameters
--]]
local function getAvailableVDParams()
  local graph = api.getGraph(api.apiType.MOBILE, api.eventType.REQUEST, m.rpc.get)
  local vdParams = {}
  for _, data in pairs(graph) do
    if data.parentId == nil then vdParams[data.name] = true end
  end
  -- print not defined in API parameters
  for k in pairs(m.vd) do
    if vdParams[k] == nil then
      m.cprint(color.magenta, "Not found in API VD parameter:", k)
    end
  end
  -- remove disabled parameters
  for k in pairs(vdParams) do
    if m.vd[k] == nil then
      vdParams[k] = nil
      if not isRestricted then m.cprint(color.magenta, "Disabled VD parameter:", k) end
    end
  end
  return vdParams
end

local vdParams = getAvailableVDParams()

--[[ @updatePreloadedPTFile: Update preloaded file with additional permissions
--! @parameters:
--! pGroup: table with additional updates (optional)
--! @return: none
--]]
local function updatePreloadedPTFile(pGroup)
  local params = { }
  for param in pairs(m.vd) do
    table.insert(params, param)
  end
  local rpcs = { "GetVehicleData", "OnVehicleData", "SubscribeVehicleData", "UnsubscribeVehicleData" }
  local levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" }
  local pt = actions.sdl.getPreloadedPT()
  if not pGroup then
    pGroup = {
      rpcs = {}
    }
    for _, rpc in pairs(rpcs) do
      pGroup.rpcs[rpc] = {
        hmi_levels = levels,
        parameters = params
      }
    end
  end
  for _, data in pairs(pGroup.rpcs) do
    if #data.parameters == 0 then data.parameters = json.EMPTY_ARRAY end
  end
  pt.policy_table.functional_groupings["VDGroup"] = pGroup
  pt.policy_table.app_policies["default"].groups = { "Base-4", "VDGroup" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  actions.sdl.setPreloadedPT(pt)
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

--[[ @isSubscribable: Check whether VD parameter is subscribable
--! E.g. it's not possible to subscribe to 'vin' VD parameter
--! @parameters:
--! pParam: name of the VD parameter
--! @return: true if it's possible to subscribe to VD parameter, otherwise - false
--]]
function m.isSubscribable(pParam)
  if m.vd[pParam] ~= "" then return true end
  return false
end

--[[ @getVDParams: Return VD parameters and values
--! @parameters:
--! pIsSubscribable: true if parameter is available for subscription, otherwise - false
--! @return: table with VD parameters and values
--]]
function m.getVDParams(pIsSubscribable)
  if pIsSubscribable == nil then return vdParams end
  local out = {}
  for param in pairs(m.vd) do
    if pIsSubscribable == m.isSubscribable(param) then out[param] = true end
  end
  return out
end

--[[ @getAnotherSubVDParam: Return another available VD parameter for subscription
--! @parameters:
--! pParam: name of the VD parameter
--! @return: another VD parameter
--]]
function m.getAnotherSubVDParam(pParam)
  local params = m.getVDParams(true)
  local sortedParams = {}
  for k in m.spairs(params) do
    table.insert(sortedParams, k)
  end
  for i, p in pairs(sortedParams) do
    if p == pParam then
      if i == #sortedParams then
        return sortedParams[1]
      else
        return sortedParams[i+1]
      end
    end
  end
end

--[[ @getVehicleData: Successful processing of GetVehicleData RPC
--! @parameters:
--! pParam: name of the VD parameter
--! pValue: data for HMI response
--! @return: none
--]]
function m.getVehicleData(pParam, pValue)
  if pValue == nil then pValue = m.vdValues[pParam] end
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { [pParam] = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { [pParam] = true })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = pValue })
  end)
  m.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", [pParam] = pValue })
end

--[[ @processRPCFailure: Processing VehicleData RPC with ERROR resultCode
--! @parameters:
--! pRPC: RPC for mobile request
--! pParam: name of the VD parameter
--! pResult: expected result code
--! pRequestValue: data for App request
--! @return: none
--]]
function m.processRPCFailure(pRPC, pParam, pResult, pRequestValue)
  if pRequestValue == nil then pRequestValue = true end
  local cid = m.getMobileSession():SendRPC(pRPC, { [pParam] = pRequestValue })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResult })
end

--[[ @processRPCgenericError: Processing VehicleData RPC with invalid HMI response
--! @parameters:
--! pRPC: RPC for mobile request
--! pParam: name of the VD parameter
--! pValue: data for HMI response
--! @return: none
--]]
function m.processRPCgenericError(pRPC, pParam, pValue)
  local cid = m.getMobileSession():SendRPC(pRPC, { [pParam] = true })
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { [pParam] = true })
  :Do(function(_,data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = pValue })
  end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ @processSubscriptionRPC: Processing SubscribeVehicleData and UnsubscribeVehicleData RPCs
--! @parameters:
--! pRPC: RPC for mobile request
--! pParam: name of the VD parameter
--! pAppId: application number (1, 2, etc.)
--! isRequestOnHMIExpected: if true or omitted VI.Sub/UnsubscribeVehicleData request is expected on HMI,
--!   otherwise - not expected
--! @return: none
--]]
function m.processSubscriptionRPC(pRPC, pParam, pAppId, isRequestOnHMIExpected)
  if pAppId == nil then pAppId = 1 end
  if isRequestOnHMIExpected == nil then isRequestOnHMIExpected = true end
  local response = {
    dataType = m.vd[pParam],
    resultCode = "SUCCESS"
  }
  local responseParam = pParam
  if pParam == "clusterModeStatus" then responseParam = "clusterModes" end
  local cid = m.getMobileSession(pAppId):SendRPC(pRPC, { [pParam] = true })
  if isRequestOnHMIExpected == true then
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC, { [pParam] = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [responseParam] = response })
    end)
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRPC):Times(0)
  end
  m.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", [responseParam] = response })
  local ret = m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
  return ret
end

--[[ @sendOnVehicleData: Processing OnVehicleData RPC
--! @parameters:
--! pParam: name of the VD parameter
--! pExpTime: number of notifications (0, 1 or more)
--! pValue: data for the notification
--! @return: none
--]]
function m.sendOnVehicleData(pParam, pExpTime, pValue)
  if pExpTime == nil then pExpTime = 1 end
  if pValue == nil then pValue = m.vdValues[pParam] end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { [pParam] = pValue })
  m.getMobileSession():ExpectNotification("OnVehicleData", { [pParam] = pValue })
  :Times(pExpTime)
end

--[[ @sendOnVehicleDataTwoApps: Processing OnVehicleData RPC for two apps
--! @parameters:
--! pParam: name of the VD parameter
--! pExpTimesApp1: number of notifications for 1st app
--! pExpTimesApp2: number of notifications for 2nd app
--! @return: none
--]]
function m.sendOnVehicleDataTwoApps(pParam, pExpTimesApp1, pExpTimesApp2)
  local value = m.vdValues[pParam]
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { [pParam] = value })
  m.getMobileSession(1):ExpectNotification("OnVehicleData", { [pParam] = value })
  :Times(pExpTimesApp1)
  m.getMobileSession(2):ExpectNotification("OnVehicleData", { [pParam] = value })
  :Times(pExpTimesApp2)
end

--[[ @unexpectedDisconnect: Unexpected disconnect sequence
--! @parameters:
--! pParam1: name of the VD parameter
--! pParam2: name of the VD parameter
--! @return: none
--]]
function m.unexpectedDisconnect(pParam1, pParam2)
  local expTimes = 0
  if pParam1 and pParam2 then expTimes = 2
  elseif pParam1 or pParam2 then expTimes = 1 end
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData")
  :ValidIf(function(_, data)
    if data.params[pParam1] == true or data.params[pParam2] == true then
      return true
    else
      return false, "VehicleInfo.UnsubscribeVehicleData request contains unexpected parameter" ..
        utils.tableToString(data.params)
    end
  end)
  :Times(expTimes)
  actions.mobile.disconnect()
  utils.wait(1000)
end

--[[ @unregisterAppWithUnsubscription: Unregister App sequence
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.unregisterAppWithUnsubscription(pParam, pAppId, isRequestOnHMIExpected)
  if pAppId == nil then pAppId = 1 end
  if isRequestOnHMIExpected == nil then isRequestOnHMIExpected = true end
  local response = {
    dataType = m.vd[pParam],
    resultCode = "SUCCESS"
  }
  local responseParam = pParam
  if pParam == "clusterModeStatus" then responseParam = "clusterModes" end
  if isRequestOnHMIExpected == true then
    m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { [pParam] = true })
    :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [responseParam] = response })
    end)
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData"):Times(0)
  end
  local mobileSession = m.getMobileSession(pAppId)
  local cid = mobileSession:SendRPC("UnregisterAppInterface",{})
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false })
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ @ignitionOff: Ignition Off sequence
--! @parameters:
--! pParam1: name of the VD parameter
--! pParam2: name of the VD parameter
--! @return: none
--]]
function m.ignitionOff(pParam1, pParam2)
  local expTimes = 0
  if pParam1 and pParam2 then expTimes = 2
  elseif pParam1 or pParam2 then expTimes = 1 end
  local isOnSDLCloseSent = false
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData")
    :ValidIf(function(_, data)
      if data.params[pParam1] == true or data.params[pParam2] == true then
        return true
      else
        return false, "VehicleInfo.UnsubscribeVehicleData request contains unexpected parameter" ..
          utils.tableToString(data.params)
      end
    end)
    :Times(expTimes)
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then m.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

--[[ @registerAppWithResumption: Successful app registration with resumption
--! @parameters:
--! pParam: name of the VD parameter
--! pAppId: application number (1, 2, etc.)
--! isRequestOnHMIExpected: if true VD.SubscribeVehicleData request is expected on HMI, otherwise - not expected
--! @return: none
--]]
function m.registerAppWithResumption(pParam, pAppId, isRequestOnHMIExpected)
  if not pAppId then pAppId = 1 end
  local response = {
    dataType = m.vd[pParam],
    resultCode = "SUCCESS"
  }
  local responseParam = pParam
  if pParam == "clusterModeStatus" then responseParam = "clusterModes" end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
    local appParams = utils.cloneTable(actions.app.getParams(pAppId))
    appParams.hashID = m.getHashId(pAppId)
    local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", appParams)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    :Do(function()
      if isRequestOnHMIExpected == true then
        m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { [pParam] = true })
        :Do(function(_, data)
          m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [responseParam] = response })
        end)
      else
        m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData"):Times(0)
      end
    end)
    m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
  end)
end

--[[ @setAppVersion: Set application version based on VD parameter version
--! @parameters:
--! pParamVersion: version of the VD parameter
--! pOperator: operator to get target app version (increase or decrease)
--! @return: none
--]]
function m.setAppVersion(pParamVersion, pOperator)
  m.cprint(color.magenta, "Param version:", pParamVersion)
  local major = tonumber(utils.splitString(pParamVersion, ".")[1]) or 0
  local minor = tonumber(utils.splitString(pParamVersion, ".")[2]) or 0
  local patch = tonumber(utils.splitString(pParamVersion, ".")[3]) or 0
  local ver = (major*100 + minor*10 + patch) + pOperator
  if ver < 450 then ver = 450 end
  ver = tostring(ver)
  major = tonumber(string.sub(ver, 1, 1))
  minor = tonumber(string.sub(ver, 2, 2))
  patch = tonumber(string.sub(ver, 3, 3))
  m.cprint(color.magenta, "App version:", major .. "." .. minor .. "." .. patch)
  actions.app.getParams().syncMsgVersion.majorVersion = major
  actions.app.getParams().syncMsgVersion.minorVersion = minor
  actions.app.getParams().syncMsgVersion.patchVersion = patch
end

--[[ @getKeyByValue: Get key from table by defined value
--! @parameters:
--! pTbl: table for lookup
--! pValue: value for lookup
--! @return: key
--]]
function m.getKeyByValue(pTbl, pValue)
  for k, v in pairs(pTbl) do
    if v == pValue then return k end
  end
  return nil
end

--[[ Params Generator Functions ]]------------------------------------------------------------------

--[[ @getParamsValidDataTestForRequest: Provide parameters for processing valid sequence for 'GetVehicleData' request
--! @parameters:
--! pGraph: graph with structure of parameters
--! @return: table with parameters
--]]
local function getParamsValidDataTestForRequest(pGraph)
  local request = { [paramName] = true }
  local hmiResponse = gen.getParamValues(pGraph)
  local mobileResponse = utils.cloneTable(hmiResponse)
  mobileResponse.success = true
  mobileResponse.resultCode = "SUCCESS"
  local params = {
    mobile = {
      name = rpc,
      request = request,
      response = mobileResponse
    },
    hmi = {
      name = m.rpcHMIMap[rpc],
      request = request,
      response = hmiResponse
    }
  }
  return params
end

--[[ @getParamsInvalidDataTestForRequest: Provide parameters for processing invalid sequence for 'GetVehicleData' request
--! @parameters:
--! pGraph: graph with structure of parameters
--! @return: table with parameters
--]]
local function getParamsInvalidDataTestForRequest(pGraph)
  local request = { [paramName] = true }
  local hmiResponse = gen.getParamValues(pGraph)
  local params = {
    mobile = {
      name = rpc,
      request = request,
      response = { success = false, resultCode = "GENERIC_ERROR" }
    },
    hmi = {
      name = m.rpcHMIMap[rpc],
      request = request,
      response = hmiResponse
    }
  }
  return params
end

--[[ @getParamsAnyDataTestForNotification: Provide parameters for processing any sequence for 'OnVehicleData' notification
--! @parameters:
--! pGraph: graph with structure of parameters
--! @return: table with parameters
--]]
local function getParamsAnyDataTestForNotification(pGraph)
  local notification = gen.getParamValues(pGraph)
  local params = {
    mobile = {
      name = rpc,
      notification = { [paramName] = notification[paramName] }
    },
    hmi = {
      name = m.rpcHMIMap[rpc],
      notification = { [paramName] = notification[paramName] }
    }
  }
  return params
end

local getParamsFuncMap = {
  VALID = {
   [api.eventType.RESPONSE] = getParamsValidDataTestForRequest,
   [api.eventType.NOTIFICATION] = getParamsAnyDataTestForNotification
  },
  INVALID = {
   [api.eventType.RESPONSE] = getParamsInvalidDataTestForRequest,
   [api.eventType.NOTIFICATION] = getParamsAnyDataTestForNotification
  }
}

--[[ Test Cases Generator Function ]]---------------------------------------------------------------

--[[ @createTestCases: Generate test cases depends on API structure of VD parameter and various options
--! @parameters:
--! pAPIType: type of the API, e.g. 'mobile' or 'hmi'
--! pEventType: type of the event, e.g. 'request', 'response' or 'notification'
--! pFuncName: name of the API function, e.g. 'GetVehicleData'
--! pIsMandatory: defines how mandatory parameters is going to be handled (see 'm.isMandatory')
--! pIsArray: defines how array parameters is going to be handled (see 'm.isArray')
--! pIsVersion: defines how parameters with version defined is going to be handled (see 'm.isVersion')
--! pDataTypes: list of data types included into processing, e.g. 'api.dataType.INTEGER.type'
--! @return: table with test cases
--]]
local function createTestCases(pAPIType, pEventType, pFuncName, pIsMandatory, pIsArray, pIsVersion, pDataTypes)

  --[[
  Build a graph object which is a flattened list representation of all parameters defined in a particular API function.
  It includes all hierarchy of parameters and sub-parameters. E.g.:
    root-level  0 - bodyInformation
    child-level 1 - roofStatuses
    child-level 2 - location
    child-level 3 - rowspan
  It's a 'key:value' list, where
    - 'key' is a unique integer ID for the parameter (or sub-parameter)
    - 'value' is a table of properties for the parameter, such as:
      - parentId - ID of the parent for this parameter (or nil for root-level parameters)
      - name - name of the parameter
      - <restrictions>, such as 'type', 'array', 'mandatory', 'since' etc. copied from API
  --]]
  local graph = api.getGraph(pAPIType, pEventType, pFuncName)

  --[[ @getParents: Get table with all parents for parameter defined by pId
  --! @parameters:
  --! pGraph: graph with all parameters
  --! pId: parameter identifier
  --! @return: table with parent parameters identifiers
  --]]
  local function getParents(pGraph, pId)
    local out = {}
    pId = pGraph[pId].parentId
    while pId do
      out[pId] = true
      pId = pGraph[pId].parentId
    end
    return out
  end

  --[[ @getMandatoryNeighbors: Get table with mandatory neighbors for parameters defined by pId and pParentIds
  --! @parameters:
  --! pGraph: graph with all parameters
  --! pId: parameter identifier
  --! pParentIds: table with parent parameters identifiers
  --! @return: table with mandatory neighbors parameters identifiers
  --]]
  local function getMandatoryNeighbors(pGraph, pId, pParentIds)
    local parentIds = utils.cloneTable(pParentIds)
    parentIds[pId] = true
    local out = {}
    for p in pairs(parentIds) do
      for k, v in pairs(pGraph) do
        if v.parentId == pGraph[p].parentId and v.mandatory and p ~= k then
          out[k] = true
        end
      end
    end
    return out
  end

  --[[ @getMandatoryChildren: Get table with mandatory children for parameter defined by pId
  --! @parameters:
  --! pGraph: graph with all parameters
  --! pId: parameter identifier
  --! pChildrenIds: output table with mandatory children parameters identifiers
  --! @return: table with mandatory children parameters identifiers
  --]]
  local function getMandatoryChildren(pGraph, pId, pChildrenIds)
    for k, v in pairs(pGraph) do
      if v.parentId == pId and v.mandatory then
        pChildrenIds[k] = true
        getMandatoryChildren(pGraph, k, pChildrenIds)
      end
    end
    return pChildrenIds
  end

  --[[ @getTCParamsIds: Merge all parameters identifiers required for the test case into one table
  --! @parameters:
  --! pId: parameter identifier
  --! ...: all tables with parameters identifiers
  --! @return: table with merged parameters identifiers
  --]]
  local function getTCParamsIds(pId, ...)
    local ids = {}
    ids[pId] = true
    for _, arg in pairs({...}) do
      if type(arg) == "table" then
        for p in pairs(arg) do
          ids[p] = true
        end
      end
    end
    return ids
  end

  --[[ @getUpdatedParams: Filter graph by defined parameters
  --! @parameters:
  --! pGraph: initial graph with all parameters
  --! pParamIds: table with parameters identifiers
  --! @return: filtered graph
  --]]
  local function getUpdatedParams(pGraph, pParamIds)
    for k in pairs(pGraph) do
      if not pParamIds[k] then
        pGraph[k] = nil
      end
    end
    return pGraph
  end

  --[[ @getTestCases: Get test cases from graph
  --! @parameters:
  --! pGraph: graph with all parameters
  --! @return: table with test cases
  --]]
  local function getTestCases(pGraph)
    --[[ @getMandatoryCondition: Check mandatory condition for the parameter
    --! @parameters:
    --! pMandatory - 'mandatory' attribute of the parameter defined in API
    --! @return: true if mandatory condition is met
    --]]
    local function getMandatoryCondition(pMandatory)
      if pIsMandatory == m.isMandatory.ALL then return true
      else return pIsMandatory == pMandatory
      end
    end
    --[[ @getArrayCondition: Check array condition for the parameter
    --! @parameters:
    --! pArray - 'array' attribute of the parameter defined in API
    --! @return: true if array condition is met
    --]]
    local function getArrayCondition(pArray)
      if pIsArray == m.isArray.ALL then return true
      else return pIsArray == pArray
      end
    end
    --[[ @getVersionCondition: Check version condition for the parameter
    --! @parameters:
    --! pSince - 'since' attribute of the parameter defined in API
    --! pDeprecated - 'deprecated' attribute of the parameter defined in API
    --! @return: true if version condition is met
    --]]
    local function getVersionCondition(pSince, pDeprecated)
      if pIsVersion == m.isVersion.ALL then return true end
      if pSince ~= nil and pDeprecated ~= true then return true end
      return false
    end
    --[[ @getTypeCondition: Check type condition for the parameter
    --! @parameters:
    --! pType - type of the parameter, see 'APIHelper.dataType' table
    --! @return: true if type condition is met
    --]]
    local function getTypeCondition(pType)
      if pDataTypes == nil or #pDataTypes == 0 then return true
      elseif utils.isTableContains(pDataTypes, pType) then return true
      else return false
      end
    end
    --[[ @getParamNameCondition: Check name condition for the parameter
    --! @parameters:
    --! pName - name of the parameter
    --! @return: true if name condition is met
    --]]
    local function getParamNameCondition(pName)
      if paramName == nil or paramName == "" then return true end
      if (pName == paramName) or (string.find(pName .. ".", paramName .. "%.") == 1) then return true end
      return false
    end
    --[[
    Iterate through all the parameters and sub-parameters defined in graph object.
    Check whether various conditions are met and include a test case in table with test cases if so.
    Test case is a table with elements:
      - 'paramId' - Id of the parameter to be tested
      - 'graph' - reduced graph object with all parameter Ids required for the test case
      Later this object is used for creating a hierarchy of parameters with their values.
    --]]
    local tcs = {}
    for k, v in pairs(pGraph) do
      local paramFullName = api.getFullParamName(graph, k)
      if getMandatoryCondition(v.mandatory) and getArrayCondition(v.array)
        and getTypeCondition(v.type) and getParamNameCondition(paramFullName)
        and getVersionCondition(v.since, v.deprecated) then
        local parentIds = getParents(graph, k)
        local childrenIds = getMandatoryChildren(graph, k, {})
        local neighborsIds = getMandatoryNeighbors(graph, k, parentIds)
        local neighborsChildrenIds = {}
        for id in pairs(neighborsIds) do
          getMandatoryChildren(graph, id, neighborsChildrenIds)
        end
        local tcParamIds = getTCParamsIds(k, parentIds, neighborsIds, childrenIds, neighborsChildrenIds)
        local tc = {
          paramId = k,
          graph = getUpdatedParams(utils.cloneTable(graph), tcParamIds)
        }
        table.insert(tcs, tc)
      end
    end
    return tcs
  end

  local tcs = getTestCases(graph)

  return tcs
end

--[[ Tests Generator Functions ]]-------------------------------------------------------------------

--[[ @getValidRandomTests: Generate tests for VALID_RANDOM_SUB test type
--! @parameters: none
--! @return: table with tests
--]]
local function getValidRandomTests()
  local tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.ALL, {})
  local tests = {}
  for _, tc in pairs(tcs) do
    local paramData = tc.graph[tc.paramId]
    if paramData.type ~= api.dataType.STRUCT.type and paramData.parentId ~= nil then
      table.insert(tests, {
          name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId),
          params = getParamsFuncMap.VALID[rpcType](tc.graph),
        })
    end
  end
  return tests
end

--[[ @getOnlyMandatoryTests: Generate tests for MANDATORY_ONLY test type
--! @parameters: none
--! @return: table with tests
--]]
local function getOnlyMandatoryTests()
  local function isTCExist(pExistingTCs, pTC)
    local tc = utils.cloneTable(pTC)
    tc.paramId = nil
    for _, e in pairs(pExistingTCs) do
      local etc = utils.cloneTable(e)
      etc.paramId = nil
      if utils.isTableEqual(etc, tc) then return true end
    end
    return false
  end
  local function filterDuplicates(pTCs)
    local existingTCs = {}
    for _, tc in pairs(pTCs) do
      if not isTCExist(existingTCs, tc) then
        tc.paramId = tc.graph[tc.paramId].parentId
        table.insert(existingTCs, tc)
      end
    end
    return existingTCs
  end
  local tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.YES, m.isArray.ALL, m.isVersion.ALL, {})
  tcs = filterDuplicates(tcs)
  local tests = {}
  for _, tc in pairs(tcs) do
    table.insert(tests, {
        name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId),
        params = getParamsFuncMap.VALID[rpcType](tc.graph),
        paramId = tc.paramId,
        graph = tc.graph
      })
  end
  return tests
end

--[[ @getInBoundTests: Generate tests for LOWER_IN_BOUND/UPPER_IN_BOUND test types
--! @parameters: none
--! @return: table with tests
--]]
local function getInBoundTests()
  local tests = {}
  -- tests simple data types
  local dataTypes = { api.dataType.INTEGER.type, api.dataType.FLOAT.type, api.dataType.DOUBLE.type, api.dataType.STRING.type }
  local tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.ALL, dataTypes)
  for _, tc in pairs(tcs) do
    tc.graph[tc.paramId].valueType = boundValueTypeMap[testType]
    table.insert(tests, {
        name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId),
        params = getParamsFuncMap.VALID[rpcType](tc.graph),
      })
  end
  -- tests for arrays
  tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.YES, m.isVersion.ALL, {})
  for _, tc in pairs(tcs) do
    tc.graph[tc.paramId].valueTypeArray = boundValueTypeMap[testType]
    table.insert(tests, {
        name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId) .. "_ARRAY",
        params = getParamsFuncMap.VALID[rpcType](tc.graph),
      })
  end
  return tests
end

--[[ @getOutOfBoundTests: Generate tests for LOWER_OUT_OF_BOUND/UPPER_OUT_OF_BOUND test types
--! @parameters: none
--! @return: table with tests
--]]
local function getOutOfBoundTests()
  local tests = {}
  -- tests for simple data types
  local dataTypes = { api.dataType.INTEGER.type, api.dataType.FLOAT.type, api.dataType.DOUBLE.type, api.dataType.STRING.type }
  local tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.ALL, dataTypes)
  for _, tc in pairs(tcs) do
    local function isSkipped()
      local paramData = tc.graph[tc.paramId]
      if paramData.type == api.dataType.STRING.type then
        if (testType == m.testType.LOWER_OUT_OF_BOUND and paramData.minlength == 0)
        or (testType == m.testType.UPPER_OUT_OF_BOUND and paramData.maxlength == nil) then
          return true
        end
      else
        if (testType == m.testType.LOWER_OUT_OF_BOUND and paramData.minvalue == nil)
        or (testType == m.testType.UPPER_OUT_OF_BOUND and paramData.maxvalue == nil) then
          return true
        end
      end
      return false
    end
    if not isSkipped() then
      tc.graph[tc.paramId].valueType = boundValueTypeMap[testType]
      table.insert(tests, {
          name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId),
          params = getParamsFuncMap.INVALID[rpcType](tc.graph),
        })
    end
  end
  -- tests for arrays
  tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.YES, m.isVersion.ALL, {})
  for _, tc in pairs(tcs) do
    local function isSkipped()
      local paramData = tc.graph[tc.paramId]
      if (testType == m.testType.LOWER_OUT_OF_BOUND and (paramData.minsize == 0 or paramData.minsize == nil))
        or (testType == m.testType.UPPER_OUT_OF_BOUND and paramData.maxsize == nil) then
        return true
      end
      return false
    end
    if not isSkipped() then
      tc.graph[tc.paramId].valueTypeArray = boundValueTypeMap[testType]
      table.insert(tests, {
          name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId) .. "_ARRAY",
          params = getParamsFuncMap.INVALID[rpcType](tc.graph),
        })
    end
  end
  -- tests for enums
  tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.ALL, { api.dataType.ENUM.type })
  for _, tc in pairs(tcs) do
    local function isSkipped()
      local paramData = tc.graph[tc.paramId]
      if paramData.type == api.dataType.ENUM.type and testType == m.testType.LOWER_OUT_OF_BOUND then
        return true
      end
      return false
    end
    --[[ @getMandatoryValues: Get hierarchy levels of parameters starting from current and to the root
    -- with mandatory value for each
    --! @parameters:
    --! pId: parameter identifier (in graph)
    --! pLevel: level of hierarchy
    --! pOut: table with result
    --! @return: table with levels and mandatory values
    --]]
    local function getMandatoryValues(pId, pLevel, pOut)
      pOut[pLevel] = tc.graph[pId].mandatory
      local parentId = tc.graph[pId].parentId
      if parentId then return getMandatoryValues(parentId, pLevel+1, pOut) end
      return pOut
    end
    local mandatoryValues = getMandatoryValues(tc.paramId, 1, {})
    if not isSkipped() and (#mandatoryValues == 1 or mandatoryValues[#mandatoryValues-1]) then
      local invalidValue = "INVALID_VALUE"
      tc.graph[tc.paramId].data = { invalidValue }
      local params = getParamsFuncMap.INVALID[rpcType](tc.graph)
      table.insert(tests, {
          name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId) .. "_" .. invalidValue,
          params = params
        })
    end
  end
  return tests
end

--[[ @getEnumItemsTests: Generate tests for ENUM_ITEMS test type
--! @parameters: none
--! @return: table with tests
--]]
local function getEnumItemsTests()
  local tests = {}
  local dataTypes = { api.dataType.ENUM.type }
  local tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.ALL, dataTypes)
  for _, tc in pairs(tcs) do
    for _, item in pairs(tc.graph[tc.paramId].data) do
      local tcUpd = utils.cloneTable(tc)
      tcUpd.graph[tc.paramId].data = { item }
      table.insert(tests, {
          name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId) .. "_" .. item,
          params = getParamsFuncMap.VALID[rpcType](tcUpd.graph)
        })
    end
  end
  return tests
end

--[[ @getBoolItemsTests: Generate tests for BOOL_ITEMS test type
--! @parameters: none
--! @return: table with tests
--]]
local function getBoolItemsTests()
  local tests = {}
  local dataTypes = { api.dataType.BOOLEAN.type }
  local tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.ALL, dataTypes)
  for _, tc in pairs(tcs) do
    for _, item in pairs({ true, false }) do
      local tcUpd = utils.cloneTable(tc)
      tcUpd.graph[tc.paramId].data = { item }
      table.insert(tests, {
          name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId) .. "_" .. tostring(item),
          params = getParamsFuncMap.VALID[rpcType](tcUpd.graph)
        })
    end
  end
  return tests
end

--[[ @getVersionTests: Generate tests for PARAM_VERSION test type
--! @parameters: none
--! @return: table with tests
--]]
local function getVersionTests()
  local tests = {}
  local tcs = createTestCases(api.apiType.MOBILE, api.eventType.REQUEST, rpc,
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.YES, {})
  for _, tc in pairs(tcs) do
    local name = tc.graph[tc.paramId].name
    if vdParams[name] then
      table.insert(tests, {
          param = tc.graph[tc.paramId].name,
          version = tc.graph[tc.paramId].since
        })
    end
  end
  return tests
end

--[[ @getValidRandomAllTests: Generate tests for VALID_RANDOM_ALL test type
--! @parameters: none
--! @return: table with tests
--]]
local function getValidRandomAllTests()
  local tests = {}
  local graph = api.getGraph(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc])
  local function getParamId(pGraph, pName)
    for k, v in pairs(pGraph) do
      if v.parentId == nil and v.name == pName then return k end
    end
    return nil
  end
  local paramId = getParamId(graph, paramName)

  graph = api.getBranch(graph, paramId)
  local tc = { graph = graph, paramId = paramId }
  table.insert(tests, {
      name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId),
      params = getParamsFuncMap.VALID[rpcType](tc.graph),
      paramId = tc.paramId,
      graph = tc.graph
    })
  return tests
end

--[[ @getMandatoryMissingTests: Generate tests for MANDATORY_MISSING test type
--! @parameters: none
--! @return: table with tests
--]]
local function getMandatoryMissingTests()
  local tests = {}
  local mndTests = getOnlyMandatoryTests()
  local randomAllTests = getValidRandomAllTests()
  if #mndTests == 0 or #randomAllTests == 0 then return tests end
  for testId in pairs(mndTests) do
    for paramId in pairs(mndTests[testId].graph) do
      local graph = utils.cloneTable(randomAllTests[1].graph)
      if graph[paramId].parentId ~= nil and graph[paramId].mandatory == true then
        local name = api.getFullParamName(graph, paramId)
        local branchToDelete = api.getBranch(graph, paramId, {})
        for id in pairs(graph) do
          if branchToDelete[id] then graph[id] = nil end
        end
        table.insert(tests, {
          name = "Param_missing_" .. name,
          params = getParamsFuncMap.INVALID[rpcType](graph),
        })
      end
    end
  end
  return tests
end

--[[ @getInvalidTypeTests: Generate tests for INVALID_TYPE test type
--! @parameters: none
--! @return: table with tests
--]]
local function getInvalidTypeTests()
  local dataTypes = { api.dataType.INTEGER.type, api.dataType.FLOAT.type, api.dataType.DOUBLE.type,
    api.dataType.STRING.type, api.dataType.ENUM.type, api.dataType.BOOLEAN.type }
  local tcs = createTestCases(api.apiType.HMI, rpcType, m.rpcHMIMap[rpc],
    m.isMandatory.ALL, m.isArray.ALL, m.isVersion.ALL, dataTypes)
  local tests = {}
  for _, tc in pairs(tcs) do
    tc.graph[tc.paramId].valueType = gen.valueType.INVALID_TYPE
    table.insert(tests, {
        name = "Param_" .. api.getFullParamName(tc.graph, tc.paramId),
        params = getParamsFuncMap.INVALID[rpcType](tc.graph),
      })
  end
  return tests
end

--[[ Test Getter Functions ]]-----------------------------------------------------------------------

--[[ @getTests: Provide tests for defined test type and VD parameter
--! @parameters:
--! pRPC: name of RPC, e.g. 'GetVehicleData'
--! pTestType: test type, e.g. 'm.testType.VALID_RANDOM_ALL'
--! pParamName: name of the VD parameter
--! @return: table with tests
--]]
function m.getTests(pRPC, pTestType, pParamName)
  local rpcTypeMap = {
    [m.rpc.get] = api.eventType.RESPONSE,
    [m.rpc.on] = api.eventType.NOTIFICATION
  }
  rpc = pRPC
  rpcType = rpcTypeMap[pRPC]
  testType = pTestType
  paramName = pParamName

  local testTypeMap = {
    [m.testType.VALID_RANDOM_ALL] = getValidRandomAllTests,
    [m.testType.VALID_RANDOM_SUB] = getValidRandomTests,
    [m.testType.LOWER_IN_BOUND] = getInBoundTests,
    [m.testType.UPPER_IN_BOUND] = getInBoundTests,
    [m.testType.LOWER_OUT_OF_BOUND] = getOutOfBoundTests,
    [m.testType.UPPER_OUT_OF_BOUND] = getOutOfBoundTests,
    [m.testType.INVALID_TYPE] = getInvalidTypeTests,
    [m.testType.ENUM_ITEMS] = getEnumItemsTests,
    [m.testType.BOOL_ITEMS] = getBoolItemsTests,
    [m.testType.PARAM_VERSION] = getVersionTests,
    [m.testType.MANDATORY_ONLY] = getOnlyMandatoryTests,
    [m.testType.MANDATORY_MISSING] = getMandatoryMissingTests,

  }
  if testTypeMap[testType] then return testTypeMap[testType]() end
  return {}
end

--[[ @processRequest: Processing sequence for 'GetVehicleData' request
--! @parameters:
--! pParams: all parameters for the sequence
--! @return: none
--]]
function m.processRequest(pParams)
  local cid = m.getMobileSession():SendRPC(pParams.mobile.name, pParams.mobile.request)
  m.getHMIConnection():ExpectRequest(pParams.hmi.name, pParams.hmi.request)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pParams.hmi.response)
    end)
  m.getMobileSession():ExpectResponse(cid, pParams.mobile.response)
end

--[[ @processNotification: Processing sequence for 'OnVehicleData' notification
--! @parameters:
--! pParams: all parameters for the sequence
--! pTestType: test type, e.g. 'm.testType.VALID_RANDOM_ALL'
--! pParamName: name of the VD parameter
--! @return: none
--]]
function m.processNotification(pParams, pTestType, pParamName)
  local function SendNotification()
    local times = m.isExpected
    if pTestType == m.testType.LOWER_OUT_OF_BOUND or pTestType == m.testType.UPPER_OUT_OF_BOUND
      or pTestType == m.testType.MANDATORY_MISSING or pTestType == m.testType.INVALID_TYPE
      or not m.isSubscribable(pParamName) then
      times = m.isNotExpected
    end
    m.getHMIConnection():SendNotification(pParams.hmi.name, pParams.hmi.notification)
    m.getMobileSession():ExpectNotification(pParams.mobile.name, pParams.mobile.notification)
    :Times(times)
  end
  if not isSubscribed[pParamName] and m.isSubscribable(pParamName) then
    m.processSubscriptionRPC(m.rpc.sub, pParamName)
    :Do(function()
        SendNotification()
      end)
    isSubscribed[pParamName] = true
  else
    SendNotification()
  end
end

--[[ @getTestsForGetVD: Generate test steps for 'GetVehicleData' tests for defined test types
--! @parameters:
--! pTestTypes: test types
--! @return: test steps
--]]
function m.runner.getTestsForGetVD(pTestTypes)
  for param in m.spairs(m.getVDParams()) do
    m.runner.Title("VD parameter: " .. param)
    for _, tt in pairs(pTestTypes) do
      local tests = m.getTests(m.rpc.get, tt, param)
      if #tests > 0 then
        m.runner.Title("Test type: " .. m.getKeyByValue(m.testType, tt))
        for _, t in pairs(tests) do
          m.runner.Step(t.name, m.processRequest, { t.params })
        end
      end
    end
  end
end

--[[ @getTestsForOnVD: Generate test steps for 'OnVehicleData' tests for defined test types
--! @parameters:
--! pTestTypes: test types
--! @return: test steps
--]]
function m.runner.getTestsForOnVD(pTestTypes)
  for param in m.spairs(m.getVDParams()) do
    m.runner.Title("VD parameter: " .. param)
    for _, tt in pairs(pTestTypes) do
      local tests = m.getTests(m.rpc.on, tt, param)
      if #tests > 0 then
        m.runner.Title("Test type: " .. m.getKeyByValue(m.testType, tt))
        for _, t in pairs(tests) do
          m.runner.Step(t.name, m.processNotification, { t.params, tt, param })
        end
      end
    end
  end
end

--[[ @getDefaultValues: Generate default random valid values for all VD parameters
--! @parameters: none
--! @return: values for parameters
--]]
local function getDefaultValues()
  local out = {}
  local fullGraph = api.getGraph(api.apiType.HMI, api.eventType.RESPONSE, m.rpcHMIMap[m.rpc.get])
  for k, v in pairs(fullGraph) do
    if v.parentId == nil  then
      local name = v.name
      local graph = api.getBranch(fullGraph, k)
      local params = gen.getParamValues(graph)
      out[name] = params[name]
    end
  end
  return out
end

m.vdValues = getDefaultValues()

return m
