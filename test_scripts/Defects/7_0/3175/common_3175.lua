---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.isTestApplicable({ { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } })
config.defaultProtocolVersion = 2

--[[ Shared Functions ]]
local m = { }
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.start = actions.start
m.postconditions = actions.postconditions
m.getHmiConnection = actions.hmi.getConnection
m.getMobileSession = actions.mobile.getSession
m.registerApp = actions.app.register
m.getPTSFilePath = actions.sdl.getPTSFilePath
m.getPolicyAppId = actions.app.getPolicyAppId
m.getAppDataForPTU = actions.ptu.getAppData
m.tableToJsonFile = utils.tableToJsonFile

--[[ Local Variables ]]
local pts

--[[ Common Functions ]]
local function getPTS()
  local remotePts = SDL.PTS.get()
  if remotePts then
    pts = remotePts
  end
  return pts
end

function m.getPTUFromPTS()
  local pTbl = getPTS()
  if pTbl == nil then
    utils.cprint(35, "PTS file was not found, PreloadedPT is used instead")
    pTbl = actions.sdl.getPreloadedPT()
    if pTbl == nil then
      utils.cprint(35, "PreloadedPT was not found, PTU file has not been created")
      return nil
    end
  end
  if type(pTbl.policy_table) == "table" then
    pTbl.policy_table.consumer_friendly_messages = nil
    pTbl.policy_table.device_data = nil
    pTbl.policy_table.module_meta = nil
    pTbl.policy_table.usage_and_error_counts = nil
    pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
    pTbl.policy_table.module_config.preloaded_pt = nil
    pTbl.policy_table.module_config.preloaded_date = nil
    pTbl.policy_table.vehicle_data = nil
  else
    utils.cprint(35, "PTU file has incorrect structure")
  end
  return pTbl
end

function m.checkVrOnLanguageChangeProcessing()
  m.getMobileSession():ExpectNotification("OnLanguageChange", { language = "FR-FR", hmiDisplayLanguage = "EN-US" })
  m.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "LANGUAGE_CHANGE" })
  m.getHmiConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  m.getHmiConnection():SendNotification("VR.OnLanguageChange", { language = "FR-FR" })
  actions.run.wait(3000)
end

return m
