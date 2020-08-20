---------------------------------------------------------------------------------------------------
-- HMI PTU common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local utils = require('user_modules/utils')
local consts = require('user_modules/consts')
local actions = require("user_modules/sequences/actions")
local atf_logger = require("atf_logger")
local SDL = require('SDL')

--[[ Common Variables ]]
local m = {}
m.preconditions = actions.preconditions
m.start = actions.start
m.activateApp = actions.app.activate
m.postconditions = actions.postconditions
m.policyTableUpdate = actions.ptu.policyTableUpdate
m.wait = utils.wait
m.mobile = actions.mobile.getSession
m.hmi = actions.hmi.getConnection
m.getAppParams = actions.app.getParams
m.getPTS = actions.sdl.getPTS
m.getSDLIniParameter = actions.sdl.getSDLIniParameter
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.registerNoPTU = actions.app.registerNoPTU
m.register = actions.app.register
m.runAfter = actions.run.runAfter
m.unRegister = actions.app.unRegister

--[[ Common Functions ]]
--[[ @getPTUFromPTS: create policy table update table (PTU) using PTS
--! @parameters: none
--! @return: PTU table
--]]
local function getPTUFromPTS()
  local pTbl = m.getPTS()
  if pTbl == nil then
    utils.cprint(consts.color.magenta, "PTS file was not found, PreloadedPT is used instead")
    pTbl = m.getPreloadedPT()
  end
  if next(pTbl) ~= nil then
    pTbl.policy_table.consumer_friendly_messages = nil
    pTbl.policy_table.device_data = nil
    pTbl.policy_table.module_meta = nil
    pTbl.policy_table.usage_and_error_counts = nil
    pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
    pTbl.policy_table.module_config.preloaded_pt = nil
    pTbl.policy_table.module_config.preloaded_date = nil
    pTbl.policy_table.vehicle_data = nil
  end
  return pTbl
end

--[[ @ptuViaHMI: perform PTU via HMI
--! @parameters:
--! pPTUpdateFunc - function with additional updates (optional)
--! pExpNotificationFunc - function with specific expectations (optional)
--! @return: none
--]]
function m.ptuViaHMI(pPTUpdateFunc, pExpNotificationFunc)
  if pExpNotificationFunc then
    pExpNotificationFunc()
  end
  local ptuFileName = os.tmpname()
  local requestId = m.hmi():SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  m.hmi():ExpectResponse(requestId)
  :Do(function()
      local ptuTable = getPTUFromPTS()
      for i, _ in pairs(actions.mobile.getApps()) do
        ptuTable.policy_table.app_policies[actions.app.getParams(i).fullAppID] = actions.ptu.getAppData(i)
      end
      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      if not pExpNotificationFunc then
         m.hmi():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
         m.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
      end
      m.hmi():SendNotification("SDL.OnReceivedPolicyUpdate",
        { policyfile = ptuFileName })
      m.runAfter(function() os.remove(ptuFileName) end, 250)
      for id, _ in pairs(actions.mobile.getApps()) do
        m.mobile(id):ExpectNotification("OnPermissionsChange")
      end
    end)
end

--[[ @unsuccessfulPTUviaHMI: failed PTU via HMI
--! @parameters: none
--! @return: none
--]]
function m.unsuccessfulPTUviaHMI()
  local requestId = m.hmi():SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  m.hmi():ExpectResponse(requestId)
  :Do(function()
        m.hmi():ExpectNotification("SDL.OnStatusUpdate")
        :Times(0)
      for id, _ in pairs(actions.mobile.getApps()) do
        m.mobile(id):ExpectNotification("OnPermissionsChange")
        :Times(0)
      end
    end)
  m.wait(500)
end

--[[ @registerApp: register mobile application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pMobConnId - mobile connection number(1, 2, etc.)
--! @return: none
--]]
function m.registerApp(pAppId, pMobConnId)
  m.register(pAppId, pMobConnId)
  m.hmi():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" })
  :Times(2)
end

--[[ @PTUfuncWithNewGroup: function for the update of PTU table with new group "VehicleInfo-3"
--! @parameters:
--! pTbl - policy table
--! @return: none
--]]
function m.PTUfuncWithNewGroup(pTbl)
  pTbl.policy_table.functional_groupings["VehicleInfo-3"].user_consent_prompt = nil
  table.insert(pTbl.policy_table.app_policies[m.getAppParams(1).fullAppID].groups, "VehicleInfo-3")
end

--[[ @updatePreloaded: function for the updating of the preloaded file
--! @parameters:
--! pUpdFunc - function with update
--! @return: none
--]]
function m.updatePreloaded(pUpdFunc)
  local preloadedTable = m.getPreloadedPT()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pUpdFunc(preloadedTable)
  m.setPreloadedPT(preloadedTable)
end

--[[ @log: function for loging messages
--! @parameters:
--! @return: none
--]]
function m.log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(consts.color.magenta, str)
end

--[[ @checkPTUStatus: verify status of PTU
--! @parameters:
--! pExpStatus - expected status, e.g. "UPDATE_NEEDED", "UPDATING" or "UP_TO_DATE"
--! @return: none
--]]
function m.checkPTUStatus(pExpStatus)
  local cid = m.hmi():SendRequest("SDL.GetStatusUpdate")
  m.hmi():ExpectResponse(cid, { result = { status = pExpStatus }})
end

--[[ @ignitionOff: perform Ignition Off sequence
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  m.hmi():SendNotification("BasicCommunication.OnIgnitionCycleOver")
  m.hmi():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.hmi():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      m.hmi():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      m.hmi():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          SDL.DeleteFile()
          actions.mobile.getConnection():Close()
        end)
    end)
  m.wait(3000)
end

--[[ @updatePolicyDB: update value in Policy DB
--! @parameters:
--! pQuery - query which is going to be executed
--! @return: none
--]]
function m.updatePolicyDB(pQuery)
  local pathToDB = SDL.AppStorage.path() .. config.pathToSDLPolicyDB
  os.execute('sqlite3 ' .. pathToDB .. ' ' .. pQuery)
  m.wait(1000)
end

return m
