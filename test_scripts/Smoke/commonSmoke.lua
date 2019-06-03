---------------------------------------------------------------------------------------------------
-- Smoke API common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local json = require("modules/json")

local consts = require("user_modules/consts")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require('user_modules/utils')
local events = require('events')

--[[ Local Variables ]]
local hmiAppIds = {}
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

local commonSmoke = {}

commonSmoke.HMITypeStatus = {
  NAVIGATION = false,
  COMMUNICATION = false
}
commonSmoke.timeout = 5000
commonSmoke.minTimeout = 500

local function allowSDL(self)
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    { allowed = true, source = "GUI", device = { id = commonSmoke.getDeviceMAC(), name = commonSmoke.getDeviceName() }})
end

--[[Module functions]]

function commonSmoke.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile(preloadedPT)
  commonSmoke.updatePreloadedPT()
end

function commonSmoke.getDeviceName()
  return config.mobileHost .. ":" .. config.mobilePort
end

function commonSmoke.getDeviceMAC()
  local cmd = "echo -n " .. commonSmoke.getDeviceName() .. " | sha256sum | awk '{printf $1}'"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

function commonSmoke.getPathToSDL()
  return config.pathToSDL
end

function commonSmoke.getMobileAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.fullAppID
end

function commonSmoke.getSelfAndParams(...)
  local out = { }
  local selfIdx = nil
  for i,v in pairs({...}) do
    if type(v) == "table" and v.isTest then
      table.insert(out, v)
      selfIdx = i
      break
    end
  end
  local idx = 2
  for i = 1, table.maxn({...}) do
    if i ~= selfIdx then
      out[idx] = ({...})[i]
      idx = idx + 1
    end
  end
  return table.unpack(out, 1, table.maxn(out))
end

function commonSmoke.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID]
end

function commonSmoke.getPathToFileInStorage(fileName)
  return commonPreconditions:GetPathToSDL() .. "storage/"
  .. commonSmoke.getMobileAppId() .. "_"
  .. commonSmoke.getDeviceMAC() .. "/" .. fileName
end

function commonSmoke.getMobileSession(pAppId, self)
  self, pAppId = commonSmoke.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  if not self["mobileSession" .. pAppId] then
    self["mobileSession" .. pAppId] = mobile_session.MobileSession(self, self.mobileConnection)
  end
  return self["mobileSession" .. pAppId]
end

function commonSmoke.splitString(inputStr, sep)
  if sep == nil then
    sep = "%s"
  end
  local splitted, i = {}, 1
  for str in string.gmatch(inputStr, "([^"..sep.."]+)") do
    splitted[i] = str
    i = i + 1
  end
  return splitted
end

function commonSmoke.expectOnHMIStatusWithAudioStateChanged(self, pAppId, request, level)
  if pAppId == nil then pAppId = 1 end
  if request == nil then request = "BOTH" end
  if level == nil then level = "FULL" end

  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  local appParams = config["application" .. pAppId].registerAppInterfaceParams

  if appParams.isMediaApplication == true then
    if request == "BOTH" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      :Times(4)
    elseif request == "speak" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      :Times(2)
    elseif request == "alert" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      :Times(2)
    end
  elseif appParams.isMediaApplication == false then
    if request == "BOTH" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" })
      :Times(2)
    elseif request == "speak" then
      mobSession:ExpectNotification("OnHMIStatus")
      :Times(0)
    elseif request == "alert" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" })
      :Times(2)
    end
  end

end

function commonSmoke.activateApp(pAppId, self)
  self, pAppId = commonSmoke.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID]
  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = commonSmoke.GetAudibleState(pAppId), systemContext = "MAIN"})
  commonTestCases:DelayedExp(commonSmoke.minTimeout)
end

function commonSmoke.start(pHMIParams, self)
  self, pHMIParams = commonSmoke.getSelfAndParams(pHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
    self:initHMI(self)
    :Do(function()
      commonFunctions:userPrint(consts.color.magenta, "HMI initialized")
      self:initHMI_onReady(pHMIParams)
      :Do(function()
        commonFunctions:userPrint(consts.color.magenta, "HMI is ready")
        self:connectMobile()
        :Do(function()
          commonFunctions:userPrint(consts.color.magenta, "Mobile connected")
          allowSDL(self)
        end)
      end)
    end)
  end)
end

function commonSmoke.putFile(params, pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobileSession = commonSmoke.getMobileSession(pAppId, self);
  local cid = mobileSession:SendRPC("PutFile", params.requestParams, params.filePath)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function commonSmoke.SetAppType(HMIType)
  for _,v in pairs(HMIType) do
    if v == "NAVIGATION" then
      commonSmoke.HMITypeStatus["NAVIGATION"] = true
    elseif v == "COMMUNICATION" then
      commonSmoke.HMITypeStatus["COMMUNICATION"] = true
    end
  end
end

function commonSmoke.GetAudibleState(pAppId)
  if not pAppId then pAppId = 1 end
  commonSmoke.SetAppType(config["application" .. pAppId].registerAppInterfaceParams.appHMIType)
  if config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication == true or
    commonSmoke.HMITypeStatus.COMMUNICATION == true or
    commonSmoke.HMITypeStatus.NAVIGATION == true then
    return "AUDIBLE"
  elseif
    config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication == false then
    return "NOT_AUDIBLE"
  end
end

function commonSmoke.GetAppMediaStatus(pAppId)
  if not pAppId then pAppId = 1 end
  local isMediaApplication = config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication
  return isMediaApplication
end

function commonSmoke.readParameterFromSmartDeviceLinkIni(paramName)
  return commonFunctions:read_parameter_from_smart_device_link_ini(paramName)
end

function commonSmoke.postconditions()
  StopSDL()
  commonPreconditions:RestoreFile(preloadedPT)
end

function commonSmoke.updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SendLocation", "SubscribeVehicleData", "UnsubscribeVehicleData", "GetVehicleData", "UpdateTurnList",
    "AlertManeuver", "DialNumber", "ReadDID", "GetDTCs", "ShowConstantTBT"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  pt.policy_table.app_policies["0000001"] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000001"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.app_policies["0000001"].keep_context = true
  pt.policy_table.app_policies["0000001"].steal_focus = true
  utils.tableToJsonFile(pt, preloadedFile)
end

function commonSmoke.registerApp(pAppId, self)
  self, pAppId = commonSmoke.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface", config["application" .. pAppId].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, data)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.fullAppID] = data.params.application.appID
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange"):Times(AtLeast(1))
          mobSession:ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
        end)
    end)
end

function commonSmoke.ignitionOff(self)
  local timeout = 5000
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      StopSDL()
      commonTestCases:DelayedExp(1000)
    end)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  local isSDLShutDownGracefully = false
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown gracefully")
      isSDLShutDownGracefully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownGracefully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

return commonSmoke
