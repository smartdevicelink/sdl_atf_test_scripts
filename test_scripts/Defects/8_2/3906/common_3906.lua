---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/SmartDeviceLink/sdl_core/issues/3906 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = { }

--[[ Proxy Functions ]]
m.testSettings = runner.testSettings
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.start = actions.start
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.policyTableUpdate = actions.policyTableUpdate
m.getParams = actions.app.getParams
m.getPTSFilePath = actions.sdl.getPTSFilePath
m.createEvent = actions.run.createEvent
m.getHMIAppId = actions.getHMIAppId
m.cleanSessions = actions.mobile.closeSession
m.tableToJsonFile = utils.tableToJsonFile

--[[ Common Functions ]]
function m.ptuFuncHapticGroup(tbl)
  tbl.policy_table.app_policies[actions.app.getParams().fullAppID].groups = { "Base-4", "HapticGroup" }
end

function m.sendHapticDataDisallowed()
  local hapticDataParam = { hapticRectData = {{ id = 1, rect = { x = 1, y = 1.5, width = 1, height = 1.5 }}}}
  local cid = m.getMobileSession():SendRPC("SendHapticData", hapticDataParam)
  m.getHMIConnection():ExpectRequest("UI.SendHapticData")
  :Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

function m.putFile(pPTUpdateFunc, pParams)
  local putFileParams = { syncFileName = 'ptu.json', fileType = "JSON" }
  if not pParams then pParams = putFileParams end
  local ptuFileName = os.tmpname()
  local ptuTable = actions.getPTUFromPTS()
  ptuTable.policy_table.app_policies[actions.app.getPolicyAppId()] = actions.ptu.getAppData()
  if pPTUpdateFunc then
    pPTUpdateFunc(ptuTable)
  end
  utils.tableToJsonFile(ptuTable, ptuFileName)
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData"):Times(0)
  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate"):Times(0)
  m.getMobileSession():ExpectNotification("OnPermissionsChange"):Times(0)
  m.getMobileSession():ExpectNotification("SDL.OnAppPermissionChanged"):Times(0)
  local cid = m.getMobileSession():SendRPC("PutFile", pParams, ptuFileName)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnPutFile")
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function() os.remove(ptuFileName) end)
end

return m
