---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/977
---------------------------------------------------------------------------------------------------
-- Description:
-- SDL has to process required language struct in jsons for SDL4.0 feature
--
-- Precondition:
-- SDL4.0 feature is enabled in .ini file, SDL and HMI are started.
-- In case:
-- 1) App is registered app via 4th protocol.
-- 2) App sends via 'SystemRequest' json files
--  - JSONWithLanguageDefaultVrTtsLowerBound.json
--  - JSONWithLanguageDefaultVrTtsUpperBound.json
-- SDL does:
--  - SDL sends in BC.UpdateAppList values of 'vrSynonyms' and 'ttsName' from json file
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
local jsonFiles = {
  "JSONWithLanguageDefaultVrTtsLowerBound.json",
  "JSONWithLanguageDefaultVrTtsUpperBound.json"
}

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
      local exp = deviceInfo.languages[1].default
      local act = pAppData
      if exp.ttsName ~= act.ttsName[1] then
        return false, "Expected 'ttsName' is '" .. tostring(exp.ttsName)
          .. "', actual '" .. tostring(act.ttsName[1]) .. "'"
      end
      if not utils.isTableEqual(exp.vrSynonyms, act.vrSynonyms) then
        return false, "Expected 'vrSynonyms' is:\n"  .. utils.tableToString(exp.vrSynonyms)
          .. "\nactual:\n" .. utils.tableToString(act.vrSynonyms)
      end
      return
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
          :ValidIf(function(_, data)
              for _, appData in ipairs(data.params.applications) do
                local result, msg = checkParams(appData, pJsonFile)
                if result == false then return result, msg end
              end
              return true
            end)
          :Do(function(_, data)
              common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
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
for _, v in pairs(jsonFiles) do
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Create mobile connection and session", common.start)

  runner.Title("Test")
  runner.Step("Register App with OnSystemRequest Query_Apps " .. _, registerAppWithOnSystemRequestQueryApps, { v })
  runner.Step("App unregistered", unregisterApp)

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end
