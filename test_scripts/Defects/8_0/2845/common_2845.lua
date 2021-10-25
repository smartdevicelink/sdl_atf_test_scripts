---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/smartdevicelink/sdl_core/issues/2845 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local rc = require('user_modules/sequences/remote_control')
local utils = require('user_modules/utils')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Common Variables ]]
local common = { }
common.modules = rc.data.getRcModuleTypes()

--[[ Common Functions ]]
common.preconditions = actions.preconditions
common.start = rc.rc.start
common.registerAppWOPTU = actions.app.registerNoPTU
common.defineRAMode = rc.rc.defineRAMode
common.activateApp = actions.app.activate
common.postconditions = actions.postconditions

local function getRCAppConfig(pPt)
  local moduleTypes = rc.data.getRcModuleTypes()
  local groups = { "Base-4", "RemoteControl" }
  local appHMIType = { "REMOTE_CONTROL" }
  if pPt then
    local out = utils.cloneTable(pPt.policy_table.app_policies.default)
    out.moduleType = moduleTypes
    out.groups = groups
    out.AppHMIType = appHMIType
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = moduleTypes,
      groups = groups,
      AppHMIType = appHMIType
    }
  end
end

function common.preparePreloadedPT(pRCAppIds)
  local preloadedTable = actions.sdl.getPreloadedPT()
  for _, rcAppId in pairs(pRCAppIds) do
    local appId = actions.app.getParams(rcAppId).fullAppID
    preloadedTable.policy_table.app_policies[appId] = getRCAppConfig(preloadedTable)
  end
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  actions.sdl.setPreloadedPT(preloadedTable)
end

local getIdx = (function()
  local idx = 2
  local isGenerateNext = true
  return function(isNext)
      if isGenerateNext then
        idx = idx + 1
        if idx > 2 then idx = 1 end
      end
      isGenerateNext = isNext
      return idx
    end
end)()

local function getApplicableModuleData(pRpc, pModuleType, pIsModifyHmiState)
  local moduleData = rc.predefined.getSettableModuleControlData(pModuleType, getIdx(pIsModifyHmiState))
  if pRpc == "ButtonPress" then
    moduleData = {
      moduleType = pModuleType,
      moduleId = moduleData.moduleId,
      buttonName = rc.predefined.getButtonName(pModuleType),
      buttonPressMode = "SHORT"
    }
  end
  return moduleData
end

function common.rpcDenied(pModuleType, pAppId, pRpc, pResultCode)
  local moduleData = getApplicableModuleData(pRpc, pModuleType, false)
  rc.rc.rpcReject(pModuleType, moduleData.moduleId, pAppId, pRpc, moduleData, pResultCode)
end

function common.rpcAllowed(pModuleType, pAppId, pRpc)
  local moduleData = getApplicableModuleData(pRpc, pModuleType, true)
  rc.rc.rpcSuccess(pModuleType, moduleData.moduleId, pAppId, pRpc, moduleData, false)
end

function common.rpcDeniedWithConsent(pModuleType, pAppId, pRpc)
  local moduleData = getApplicableModuleData(pRpc, pModuleType, false)
  rc.rc.rpcRejectWithConsent(pModuleType, moduleData.moduleId, pAppId, pRpc, moduleData)
end

function common.rpcDeniedWithoutConsent(pModuleType, pAppId, pRpc)
  local moduleData = getApplicableModuleData(pRpc, pModuleType, false)
  rc.rc.rpcRejectWithoutConsent(pModuleType, moduleData.moduleId, pAppId, pRpc, moduleData)
end

function common.releaseModule(pModuleType, pAppId)
  local moduleData = getApplicableModuleData(nil, pModuleType, false)
  rc.rc.releaseModule(pModuleType, moduleData.moduleId, pAppId)
end

function common.getFunctionWithParameters(pTo, pModuleType, pRpc, pAppId)
  if pTo == "AUTO_ALLOW" then return common.rpcAllowed, { pModuleType, pAppId, pRpc }
  elseif pTo == "AUTO_DENY" then return common.rpcDenied, { pModuleType, pAppId, pRpc, "IN_USE" }
  elseif pTo == "ASK_DRIVER" then return common.rpcDeniedWithConsent, { pModuleType, pAppId, pRpc }
  end
  return nil, nil
end

function common.getResultDescription(pTo)
  if pTo == "AUTO_ALLOW" then return " allowed"
  elseif pTo == "AUTO_DENY" then return " denied"
  elseif pTo == "ASK_DRIVER" then return " rejected with driver consent"
  end
  return nil
end

function common.isRpcApplicable(pModuleType, pRpc)
  if pRpc == "ButtonPress" then
    return (pModuleType == "RADIO" or pModuleType == "CLIMATE") and true or false
  end
  return true
end

return common
