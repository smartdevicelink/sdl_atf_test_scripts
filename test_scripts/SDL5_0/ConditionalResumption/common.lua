---------------------------------------------------------------------------------------------------
-- Smoke API common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local json = require("modules/json")

local actions = require("user_modules/sequences/actions")
local consts = require("user_modules/consts")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local test = require("user_modules/dummy_connecttest")
local utils = require('user_modules/utils')
local runner = require('user_modules/script_runner')

--[[ Conditions to skip tests ]]
if config.defaultMobileAdapterType ~= "TCP" then
  runner.skipTest("Test is applicable only for TCP connection")
end

--[[ Local Variables ]]
local hmiAppIds = {}
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

local common = actions

common.commandArray = {}

common.appHMITypesByOption = {
  EmptyApp = {},
  Default = {"DEFAULT"},
  Communication = {"COMMUNICATION"},
  Media = {"MEDIA"},
  Messaging = {"MESSAGING"},
  Navigation = {"NAVIGATION"},
  Information = {"INFORMATION"},
  Social = {"SOCIAL"},
  BackgroundProcess = {"BACKGROUND_PROCESS"},
  Testing = {"TESTING"},
  System = {"SYSTEM"},
  Projection = {"PROJECTION"},
  RemoteControl = {"REMOTE_CONTROL"}
}

common.wait = utils.wait

--[[Module functions]]
local basePreconditions = actions.preconditions
function common.preconditions()
  basePreconditions()
  commonPreconditions:BackupFile("smartDeviceLink.ini")
  common.commandArray = {}
  local params = common.getConfigAppParams(1)
  params.hashID = nil
  common.hashID = nil
end

function common.pinOnHashChange(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Pin()
  :Times(AnyNumber())
  :Do(function(_, data)
    common.hashId = data.payload.hashID
  end)
end

function common.cleanSessions()
  for i = 1, common.getAppsCount() do
    test.mobileSession[i]:StopRPC()
    :Do(function(_, d)
        utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
        test.mobileSession[i] = nil
      end)
  end
  utils.wait()
end

function common.write_parameter_to_smart_device_link_ini(param_name, param_value)
  commonFunctions:write_parameter_to_smart_device_link_ini(param_name, param_value)
end

function common.writeLowBandwidthResumptionLevel(hmi_type, hmi_level)
  if hmi_type == "Projection" or hmi_type == "Navigation" then
    commonFunctions:write_parameter_to_smart_device_link_ini(hmi_type .. "LowBandwidthResumptionLevel", hmi_level)
  end
end

function common.writeMediaLowBandwidthResumptionLevel(hmi_level)
  commonFunctions:write_parameter_to_smart_device_link_ini("MediaLowBandwidthResumptionLevel", hmi_level)
end

function common.registrationWithResumption(pAppId, pLevelResumpFunc, pDataResump)
  if not pAppId then pAppId = 1 end
  local mobSession = common.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
    local params = common.getConfigAppParams(pAppId)
    params.hashID = common.hashId
    local corId = mobSession:SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
    test.hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = common.getConfigAppParams(pAppId).appName } })
    :Do(function(_, d1)
      common.setHMIAppId(d1.params.application.appID, pAppId)
      if pDataResump then
        pDataResump()
      end
    end)
    mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      if pLevelResumpFunc then
        pLevelResumpFunc()
      end
    end)
  end)
end

function common.getAddCommandParams(pN)
  local out = {
    cmdID = pN,
    vrCommands = { "vrCommand" .. pN},
    menuParams = {
      menuName = "Command" .. pN
    }
  }
  return out
end

function common.setAppHMIType(pAppId, pAppHMIType)
  if #pAppHMIType == 0 then pAppHMIType = nil end
  config["application" .. pAppId].registerAppInterfaceParams.appHMIType = pAppHMIType
end

function common.addCommand(pParams, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = common.getMobileSession(pAppId)
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("AddCommand", pParams)
  local requestUiParams = {
    cmdID = pParams.cmdID,
    menuParams = pParams.menuParams,
    appID = common.getHMIAppId()
  }
  EXPECT_HMICALL("UI.AddCommand", requestUiParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  if pParams.vrCommands then
    table.insert(common.commandArray, { cmdID = pParams.cmdID, vrCommand = pParams.vrCommands})
    local requestVrParams = {
      cmdID = pParams.cmdID,
      vrCommands = pParams.vrCommands,
      type = "Command",
      appID = common.getHMIAppId(pAppId)
    }
    EXPECT_HMICALL("VR.AddCommand", requestVrParams)
    :Do(function(_,data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end


function common.resumptionDataAddCommands()
  EXPECT_HMICALL("VR.AddCommand")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for _, value in pairs(common.commandArray) do
      if data.params.cmdID == value.cmdID then
        local vrCommandCompareResult = commonFunctions:is_table_equal(data.params.vrCommands, value.vrCommand)
        local Msg = ""
        if vrCommandCompareResult == false then
          Msg = "vrCommands in received VR.AddCommand are not match to expected result.\n" ..
          "Actual result:" .. common.tableToString(data.params.vrCommands) .. "\n" ..
          "Expected result:" .. common.tableToString(value.vrCommand) .."\n"
        end
        return vrCommandCompareResult, Msg
      end
    end
    return true
  end)
  :Times(#common.commandArray)

  EXPECT_HMICALL("UI.AddCommand")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for k, value in pairs(common.commandArray) do
      if data.params.cmdID == value.cmdID then
        return true
      elseif data.params.cmdID ~= value.cmdID and k == #common.commandArray then
        return false, "Received cmdID in UI.AddCommand was not added previously before resumption"
      end
    end
  end)
  :Times(#common.commandArray)
end

function common.resumptionDenied()
  EXPECT_HMICALL("VR.AddCommand"):Times(0)
  EXPECT_HMICALL("UI.AddCommand"):Times(0)
end

function common.reconnect(pAppId)
  if not pAppId then pAppId = 1 end
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    {appID = common.getHMIAppId(pAppId), unexpectedDisconnect = true})
  actions.mobile.disconnect()
  actions.run.wait(1000)
  :Do(function()
    test.mobileSession[pAppId] = mobile_session.MobileSession(
      test,
      test.mobileConnection,
      config["application" .. pAppId].registerAppInterfaceParams)
    test.mobileConnection:Connect()
  end)
end

local basePostconditions = actions.postconditions
function common.postconditions()
  basePostconditions()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

return common
