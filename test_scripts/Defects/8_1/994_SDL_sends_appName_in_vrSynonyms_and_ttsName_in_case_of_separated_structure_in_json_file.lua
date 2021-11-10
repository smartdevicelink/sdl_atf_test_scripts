---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/994
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL write a values from language struct in json for SDL4.0 feature
--  to the 'tts' and 'vrSynonym' parameters and send them via UpdateAppList to HMI in case
--  'language' struct has ttsName in default element and vrSynonyms in current HMI language and vice versa
--
-- Precondition:
-- 1. SDL4.0 feature is enabled in .ini file, SDL and HMI are started.
-- Steps:
-- 1. App is registered app via 4th protocol
-- 2. App sends via 'SystemRequest' json files
--  - JSONWithTtsNameVrSynonymsInSeparatedStructs.json
-- SDL does:
--  - sends in BC.UpdateAppList values of 'vrSynonyms' and 'ttsName' from json file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 4
common.getConfigAppParams().appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local pathToJsonFiles = "files/jsons/JSON_Language_parameter"
local jsonFiles = "JSONWithTtsNameVrSynonymsInSeparatedStructs.json"

--[[ Local Functions ]]
local function checkParams(pAppData, pJsonFile)
  local tbl = utils.jsonFileToTable(pathToJsonFiles .. "/" .. pJsonFile)
  local isAppFound = false
  for _, item in ipairs(tbl.response) do
    if pAppData.appName == common.getConfigAppParams().appName then return true end
    if item.name == pAppData.appName then
      isAppFound = true
      local deviceInfo
      if item.ios ~= nil then
        deviceInfo = item.ios
      else
        deviceInfo = item.android
      end
      local exp = {}
      for _, tab in pairs(deviceInfo.languages) do
        for l, params in pairs(tab) do
          if l == "default" then
            for p,v in pairs(params) do
              if not exp[p] then
                exp[p] = v
              end
            end
          elseif l == "EN-US" then
            for p,v in pairs(params) do
              exp[p] = v
            end
          end
        end
      end
      local act = pAppData
      if exp.ttsName ~= act.ttsName[1] then
        return false, "Expected 'ttsName' is '" .. tostring(exp.ttsName)
          .. "', actual '" .. tostring(act.ttsName[1]) .. "'"
      end
      if not utils.isTableEqual(exp.vrSynonyms, act.vrSynonyms) then
        return false, "Expected 'vrSynonyms' is:\n"  .. utils.tableToString(exp.vrSynonyms)
          .. "\nactual:\n" .. utils.tableToString(act.vrSynonyms)
      end
    end
  end
  if isAppFound == false then
    return false, "App wasn't found"
  end
  return true
end

local function registerAppWithOnSystemRequestQueryApps(pJsonFile)
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
      local cid = session:SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnHMIStatus",
          { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Do(function()
              local msg = {
                serviceType      = 7,
                frameInfo        = 0,
                rpcType          = 2,
                rpcFunctionId    = 32768,
                rpcCorrelationId = common.getMobileSession().correlationId + 30,
                payload          = '{"hmiLevel":"FULL", "audioStreamingState":"NOT_AUDIBLE", "systemContext":"MAIN"}'
              }
              common.getMobileSession():Send(msg)
            end)
        end)
    end)
  common.getMobileSession():ExpectNotification("OnSystemRequest",
    { requestType = "LOCK_SCREEN_ICON_URL" },
    { requestType = "QUERY_APPS" })
  :Times(2)
  :Do(function(_, data)
      if data.payload.requestType == "QUERY_APPS" then
        local cid = common.getMobileSession():SendRPC("SystemRequest", {
          requestType = "QUERY_APPS", fileName = pJsonFile },
          pathToJsonFiles .. "/" .. pJsonFile)
        common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList")
        :ValidIf(function(_, data1)
            local countAppExp = 3
            local countApp = #data1.params.applications
            if countApp ~= countAppExp then
              return false, "Expected number of apps is " .. countAppExp .. " in applications array,"
                .. "'actual' " .. countApp
            end
            for _, appData in ipairs(data1.params.applications) do
              local result, msg = checkParams(appData, pJsonFile)
              if result == false then return result, msg end
            end
            return true
          end)
        :Do(function(_, data2)
            common.getHMIConnection():SendResponse(data2.id, data.method, "SUCCESS", {})
          end)
        common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
      end
    end)
end

local function unregisterApp()
  local cid = common.getMobileSession():SendRPC("UnregisterAppInterface",{})
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Create mobile connection and session", common.start)

runner.Title("Test")
runner.Step("Register App with OnSystemRequest Query_Apps ", registerAppWithOnSystemRequestQueryApps, { jsonFiles })
runner.Step("App unregistered", unregisterApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
