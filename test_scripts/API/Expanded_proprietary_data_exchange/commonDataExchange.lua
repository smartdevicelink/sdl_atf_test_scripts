---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local utils = require("user_modules/utils")
local events = require("events")
local json = require("modules/json")
local runner = require('user_modules/script_runner')

-- Set applicalbe SDL policy mode
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5

local m = actions
local ptuTable = {}

--[[ @systemRequest: successful processing of SystemRequest
--! @parameters:
--! pParams - parameters for SystemRequest
--! pFile - file for SystemRequest
--! @return: none
--]]
function m.systemRequest(pParams, pFile)
  local mobSession = m.getMobileSession()
  local cid = mobSession:SendRPC("SystemRequest", pParams, pFile)
  if pParams.fileName then pParams.fileName = "/tmp/fs/mp/images/ivsu_cache/" .. pParams.fileName end
  EXPECT_HMICALL("BasicCommunication.SystemRequest",pParams)
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ @unsuccessSystemRequest: processing SystemRequest in case notification is disallowed
--! @parameters:
--! pParams - parameters for SystemRequest
--! pFile - file for SystemRequest
--! @return: none
--]]
function m.unsuccessSystemRequest(pParams, pFile)
  local mobSession = m.getMobileSession()
  local cid = mobSession:SendRPC("SystemRequest", pParams, pFile)
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ @onSystemRequest: successful processing of OnSystemRequest
--! @parameters:
--! pParams - parameters for OnSystemRequest
--! @return: none
--]]
function m.onSystemRequest(pParams)
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest", pParams)
  if pParams.fileName then pParams.fileName = nil end
  m.getMobileSession():ExpectNotification("OnSystemRequest", pParams)
end

--[[ @unsuccessOnSystemRequest: processing OnSystemRequest in case notification is disallowed
--! @parameters:
--! pParams - parameters for OnSystemRequest
--! @return: none
--]]
function m.unsuccessOnSystemRequest(pParams)
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest", pParams)
  m.getMobileSession():ExpectNotification("OnSystemRequest")
  :Times(0)
end

--[[ @getPTUFromPTS: create policy table update table (PTU)
--! @parameters:
--! pTbl - table with policy table snapshot (PTS)
--! @return: table with PTU
--]]
local function getPTUFromPTS(pTbl)
  pTbl.policy_table.consumer_friendly_messages.messages = nil
  pTbl.policy_table.device_data = nil
  pTbl.policy_table.module_meta = nil
  pTbl.policy_table.usage_and_error_counts = nil
  pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pTbl.policy_table.module_config.preloaded_pt = nil
  pTbl.policy_table.module_config.preloaded_date = nil
  pTbl.policy_table.vehicle_data = nil
end

--[[ @policyTableUpdate: perform PTU
--! @parameters:
--! pPTUpdateFunc - function with additional updates (optional)
--! pExpNotificationFunc - function with specific expectations (optional)
--! @return: none
--]]
function m.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc, pRequestSubType)
  if pExpNotificationFunc then
    pExpNotificationFunc()
  else
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  end
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptuFileName = os.tmpname()
  local requestId = m.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  m.getHMIConnection():ExpectResponse(requestId)
  :Do(function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = ptsFileName, requestSubType = pRequestSubType })
      getPTUFromPTS(ptuTable)
      for i = 1, m.getAppsCount() do
        ptuTable.policy_table.app_policies[m.getConfigAppParams(i).fullAppID] = m.getAppDataForPTU(i)
      end
      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      EXPECT_EVENT(event, "PTU event")
      for id = 1, m.getAppsCount() do
        local session = m.getMobileSession(id)
        session:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY", requestSubType = pRequestSubType })
        :Do(function()
            utils.cprint(35, "App ".. id .. " was used for PTU")
            RAISE_EVENT(event, event, "PTU event")
            local corIdSystemRequest = session:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY", requestSubType = pRequestSubType }, ptuFileName)
            EXPECT_HMICALL("BasicCommunication.SystemRequest", { requestSubType = pRequestSubType })
            :Do(function(_, d3)
                m.getHMIConnection():SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                m.getHMIConnection():SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
              end)
            session:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
            :Do(function() os.remove(ptuFileName) end)
          end)
        :Times(AtMost(1))
      end
    end)
end

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.registerApp(pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
        application = {
          appName = m.getConfigAppParams(pAppId).appName
        }
      })
      :Do(function()
          m.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d2)
              m.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
              ptuTable = utils.jsonFileToTable(d2.params.file)
            end)
      end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ @registerAppWOPTU: register mobile application and do not perform PTU
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.registerAppWOPTU(pAppId, pRequestSubType)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface", m.getConfigAppParams(pAppId))
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = {
          appName = m.getConfigAppParams(pAppId).appName,
          requestSubType = pRequestSubType
        }
      })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

return m
