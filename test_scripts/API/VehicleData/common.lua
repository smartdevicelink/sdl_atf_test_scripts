---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local json = require("modules/json")
local SDL = require("SDL")
local apiLoader = require("modules/api_loader")
local color = require("user_modules/consts").color

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}
local hashId = {}
local api = {
  hmi = apiLoader.init("data/HMI_API.xml"),
  mob = apiLoader.init("data/MOBILE_API.xml")
}

--[[ Common Proxy Functions ]]
do
  m.Title = runner.Title
  m.Step = runner.Step
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

--[[ Common Variables ]]
m.rpc = {
  get = "GetVehicleData",
  sub = "SubscribeVehicleData",
  unsub = "UnsubscribeVehicleData",
  on = "OnVehicleData"
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
  windowStatus = "VEHICLEDATA_WINDOWSTATUS"
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

--[[ API Functions ]]

math.randomseed(os.clock())

--[[ @split: Split input string by '.' into a few sub-strings
--! @parameters:
--! pStr: input string
--! @return: table with sub-strings
--]]
local function split(pStr)
  local result = {}
  for match in (pStr.."."):gmatch("(.-)%.") do
    if string.len(match) > 0 then table.insert(result, match) end
  end
  return result
end

--[[ @getParamValues: Generate VD parameter values bases on restrictions in API
-- Function iterates through all structs recursively
--! @parameters:
--! pParams: table with parameters
--! pCmnSchema: table with data representation of 'Common' interface
--! @return: table with VD parameters and values
--]]
function m.getParamValues(pParams, pCmnSchema)
  local function getTypeValue(pData)
    local itype = split(pData.type)[2]
    local function getSimpleValue()
      local tp = pData.type
      local min = 1
      local max = 30
      -- set min/max restrictions
      if tp == "Float" or tp == "Integer" then
        if pData.minvalue ~= nil then min = pData.minvalue end
        if pData.maxvalue ~= nil then max = pData.maxvalue end
      end
      if tp == "String" then
        if pData.minlength ~= nil then min = pData.minlength end
        if pData.maxlength ~= nil then max = pData.maxlength end
      end
      -- generate random value
      if tp == "Boolean" then
        return math.random(0, 1) == 1
      end
      if tp == "Float" then
        return tonumber(string.format('%.02f', math.random() + math.random(min, max-1)))
      end
      if tp == "Integer" then
        return math.random(min, max)
      end
      if tp == "String" then
        local length = math.random(min, max)
        local res = ""
        for _ = 1, length do
          res = res .. string.char(math.random(97, 122)) -- [a-z] characters
        end
        return res
      end
    end
    local function getEnumValue()
      local data = {}
      for k in m.spairs(pCmnSchema.enum[itype]) do
        table.insert(data, k)
      end
      return data[math.random(1, #data)]
    end
    local function getStructValue()
      return m.getParamValues(pCmnSchema.struct[itype].param, pCmnSchema)
    end
    if pCmnSchema.struct[itype] ~= nil then
      return getStructValue()
    elseif pCmnSchema.enum[itype] ~= nil then
      return getEnumValue()
    else
      return getSimpleValue()
    end
  end
  local function getArrayTypeValue(pData)
    local min = 1
    local max = 5
    if pData.minsize ~= nil and pData.minsize > min then min = pData.minsize end
    if pData.maxsize ~= nil and pData.maxsize < max then max = pData.maxsize end
    local numOfItems = math.random(min, max)
    local out = {}
    for _ = 1, numOfItems do
      table.insert(out, getTypeValue(pData, pCmnSchema))
    end
    return out
  end
  local out = {}
  for k, v in pairs(pParams) do
    if v.array == false then
      out[k] = getTypeValue(v)
    else
      out[k] = getArrayTypeValue(v)
    end
  end
  return out
end

--[[ @getParamValuesFromAPI: Generate VD parameter values bases on restrictions in API
-- This is a wrapper for 'm.getParamValues()' function
--! @parameters:
--! @return: table with VD parameters and values
--]]
local function getParamValuesFromAPI()
  local viSchema = api.hmi.interface["VehicleInfo"]
  local cmnSchema = api.hmi.interface["Common"]
  local params = viSchema.type.response.functions.GetVehicleData.param
  local paramValues = m.getParamValues(params, cmnSchema)
  -- print not defined in API parameters
  for k in pairs(m.vd) do
    if paramValues[k] == nil then
      m.cprint(color.magenta, "Not found in API VD parameter:", k)
    end
  end
  -- remove disabled parameters
  for k in pairs(paramValues) do
    if m.vd[k] == nil then
      paramValues[k] = nil
      m.cprint(color.magenta, "Disabled VD parameter:", k)
    end
  end
  return paramValues
end

m.vdValues = getParamValuesFromAPI()

--[[ @getMandatoryParamsFromAPI: Return VD parameters and values which has mandatory sub-parameters defined in API
--! @parameters:
--! @return: table with VD parameters and values
--]]
local function getMandatoryParamsFromAPI()
  local out = {}
  local viSchema = api.hmi.interface["VehicleInfo"]
  local cmnSchema = api.hmi.interface["Common"]
  local params = viSchema.type.response.functions.GetVehicleData.param
  for k, v in pairs(params) do
    local iface = split(v.type)[1]
    local itype = split(v.type)[2]
    if iface == "Common" then
      if cmnSchema.struct[itype] ~= nil then
        for k2, v2 in pairs(cmnSchema.struct[itype].param) do
          if v2.mandatory == "true" and m.vd[k] then
            if out[k] == nil then out[k] = { sub = {}, array = false } end
            if v.array == "true" then out[k].array = true end
            table.insert(out[k].sub, k2)
          end
        end
      end
    end
  end
  return out
end

m.mandatoryVD = getMandatoryParamsFromAPI()

--[[ @getVersioningParamsFromAPI: Return VD parameters and values which has version defined in API
--! @parameters:
--! @return: table with VD parameters and values
--]]
local function getVersioningParamsFromAPI()
  local out = {}
  local schema = api.mob.interface[next(api.mob.interface)]
  local params = schema.type.request.functions.GetVehicleData.param
  for k, v in pairs(params) do
    if v.since ~= nil and m.vd[k] and v.deprecated ~= "true" then out[k] = v.since end
  end
  return out
end

m.versioningVD = getVersioningParamsFromAPI()

--[[ Common Functions ]]

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

--[[ @getVDParams: Return VD parameters and values
--! @parameters:
--! pIsSubscribable: true if parameter is available for subscription, otherwise - false
--! @return: table with VD parameters and values
--]]
function m.getVDParams(pIsSubscribable)
  if pIsSubscribable == nil then return m.vdValues end
  local out = {}
  for param in pairs(m.vd) do
    if pIsSubscribable == (m.vd[param] ~= "") then out[param] = m.vdValues[param] end
  end
  return out
end

--[[ @getMandatoryOnlyCases: Return cases for VD parameter where only mandatory sub-parameters are defined
--! @parameters:
--! pParam: name of the VD parameter
--! @return: table with test cases where key is name of test case and value is VD parameter with value
--]]
function m.getMandatoryOnlyCases(pParam)
  local out = {}
  local value = utils.cloneTable(m.vdValues[pParam])
  local mnd = m.mandatoryVD[pParam] -- get information about mandatory sub-parameters
  local to_upd = value    -- 'to_upd' variable allows to handle non-array and array cases by the same logic
  if mnd.array then       -- in both cases 'to_upd' is a table with sub-parameters
    value = { value[1] }  -- in case of non-array it equals to param value
    to_upd = value[1]     -- in case of array it equals to 1st item of param value
  end
  -- iterate through all sub-parameters and remove all optional
  for k in pairs(to_upd) do
    if not utils.isTableContains(mnd.sub, k) then
      to_upd[k] = nil
    end
  end
  out["mandatory"] = value
  return out
end

--[[ @getMandatoryMissingCases: Return cases for VD parameter where one mandatory sub-parameter is missing
--! @parameters:
--! pParam: name of the VD parameter
--! @return: table with test cases where key is name of test case and value is VD parameter with value
--]]
function m.getMandatoryMissingCases(pParam)
  local out = {}
  local mnd = m.mandatoryVD[pParam] -- get information about mandatory sub-parameters
  -- iterate through all mandatory sub-parameters and remove one of them for each case
  for _, k in pairs(mnd.sub) do
    local value = utils.cloneTable(m.vdValues[pParam])
    local to_upd = value
    if mnd.array then
      value = { value[1] }
      to_upd = value[1]
    end
    for j in pairs(to_upd) do
      if j == k then to_upd[k] = nil end
    end
    out["missing_" .. k] = value
  end
  return out
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

--[[ @getInvalidData: Return invalid value bases on valid one
--! @parameters:
--! pData: valid value
--! @return: invalid value
--]]
function m.getInvalidData(pData)
  if type(pData) == "boolean" then return 123 end
  if type(pData) == "number" then return true end
  if type(pData) == "string" then return false end
  if type(pData) == "table" then
    for k, v in pairs(pData) do
      pData[k] = m.getInvalidData(v)
    end
    return pData
  end
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
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.setHashId(data.payload.hashID, pAppId)
  end)
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
--! pParam: name of the VD parameter
--! @return: none
--]]
function m.unexpectedDisconnect(pParam)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  if pParam then
    m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { [pParam] = true })
  end
  actions.mobile.disconnect()
  utils.wait(1000)
end

--[[ @ignitionOff: Ignition Off sequence
--! @parameters:
--! pParam: name of the VD parameter
--! @return: none
--]]
function m.ignitionOff(pParam)
  local isOnSDLCloseSent = false
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { [pParam] = true })
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
  local major = tonumber(split(pParamVersion)[1]) or 0
  local minor = tonumber(split(pParamVersion)[2]) or 0
  local patch = tonumber(split(pParamVersion)[3]) or 0
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

return m
