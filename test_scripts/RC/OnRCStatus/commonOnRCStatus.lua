---------------------------------------------------------------------------------------------------
-- OnRCStatus common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonRC = require('test_scripts/RC/commonRC')
local utils = require("user_modules/utils")
local rc = require('user_modules/sequences/remote_control')

--[[ Common Variables ]]
commonRC.wait = utils.wait
commonRC.cloneTable = utils.cloneTable
commonRC.getModulesAllocationByApp = rc.state.getModulesAllocationByApp

--[[ Common Functions ]]

function commonRC.start()
  local state = rc.state.buildDefaultActualModuleState(rc.predefined.getRcCapabilities())
  rc.state.initActualModuleStateOnHMI(state)
  rc.rc.start(rcCapabilities)
end

local originalUnregisterApp = commonRC.unregisterApp

function commonRC.unregisterApp(pAppId)
  if not pAppId then pAppId = 1 end
  rc.state.resetModulesAllocationByApp(pAppId)
  originalUnregisterApp(pAppId)
end

local originalPolicyTableUpdate = commonRC.policyTableUpdate

function commonRC.policyTableUpdate(pTUfunc, pAppId)
  if not pAppId then pAppId = 1 end
  rc.state.resetModulesAllocationByApp(pAppId)
  originalPolicyTableUpdate(pTUfunc)
end

local function exitApplication(pAppId, pReason)
  if not pAppId then pAppId = 1 end
  rc.state.resetModulesAllocationByApp(pAppId)
  local hmiAppId = commonRC.getHMIAppId()
  commonRC.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    { appID = hmiAppId, reason = pReason })
  commonRC.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
end

function commonRC.userExit(pAppId)
  exitApplication(pAppId, "USER_EXIT")
end

function commonRC.driverDistractionViolation(pAppId)
  exitApplication(pAppId, "DRIVER_DISTRACTION_VIOLATION")
end

function commonRC.disableRCFromHMI(pAppId)
  if not pAppId then pAppId = 1 end
  rc.state.resetModulesAllocationByApp(pAppId)
  commonRC.getHMIConnection():SendNotification("RC.OnRemoteControlSettings", { allowed = false })
end

function commonRC.getModules()
  return { "RADIO", "CLIMATE" }
end

function commonRC.getAllModules()
  return { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }
end

function commonRC.getHMIAppIdsRC()
  local out = {}
  for appID, hmiAppId in pairs(commonRC.getHMIAppIds()) do
    for i = 1, 5 do
      local params = config["application" .. i].registerAppInterfaceParams
      if params.fullAppID == appID and params.appHMIType[1] == "REMOTE_CONTROL" then
        table.insert(out, hmiAppId)
      end
    end
  end
  return out
end

function commonRC.registerRCApplication(pAppId, pAllowed)
  if not pAppId then pAppId = 1 end
  if pAllowed == nil then pAllowed = true end
  local freeModulesArray = {}
  if true == pAllowed then
    freeModulesArray = rc.state.getModulesAllocationByApp(pAppId).freeModules
  end
  local pModuleStatusForApp = {
    freeModules = freeModulesArray,
    allocatedModules = { },
    allowed = pAllowed
  }
  commonRC.registerAppWOPTU(pAppId)
  commonRC.validateOnRCStatusForApp(pAppId, pModuleStatusForApp)
  EXPECT_HMICALL("RC.OnRCStatus")
  :Times(0)
end

function commonRC.setModuleStatus(pModule, pAllocApp)
  if not pAllocApp then pAllocApp = 1 end
  local moduleId = commonRC.getModuleId(pModule)
  rc.state.setModuleAllocation(pModule, moduleId, pAllocApp)
  return rc.state.getModulesAllocationByApp(pAllocApp)
end

function commonRC.setModuleStatusByDeallocation(pModule, pRemoveAllocFromApp)
  if not pRemoveAllocFromApp then pRemoveAllocFromApp = 1 end
  local moduleId = commonRC.getModuleId(pModule)
  rc.state.resetModuleAllocation(pModule, moduleId)
  return rc.state.getModulesAllocationByApp(pRemoveAllocFromApp)
end

function commonRC.closeSession(pAppId)
  if not pAppId then pAppId = 1 end
  commonRC.deleteHMIAppId(pAppId)
  commonRC.getMobileSession(pAppId):Stop()
end

function commonRC.validateOnRCStatus(pAppIds)
  if not pAppIds then pAppIds =  {1} end
  local hmiExpDataTable  = { }
  for _, appId in pairs(pAppIds) do
    local rcStatusForApp = rc.state.getModulesAllocationByApp(appId)
    hmiExpDataTable[commonRC.getHMIAppId(appId)] = utils.cloneTable(rcStatusForApp)
    rcStatusForApp.allowed = true
    rc.rc.expectOnRCStatusOnMobile(appId, rcStatusForApp)
  end
  rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
end

function commonRC.validateOnRCStatusForApp(pAppId, pExpData, allowed)
 local expData = utils.cloneTable(pExpData)
 if allowed == nil then allowed = true end
 expData.allowed = allowed
 rc.rc.expectOnRCStatusOnMobile(pAppId, expData)
end

function commonRC.validateOnRCStatusForHMI(pAppId, pExpData)
  pExpData["appID"] = commonRC.getHMIAppId(pAppId)
  local hmiExpDataTable  = { }
  hmiExpDataTable[commonRC.getHMIAppId(pAppId)] = utils.cloneTable(pExpData)
  rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
end

function commonRC.registerNonRCApp(pAppId)
  commonRC.registerAppWOPTU(pAppId)
  commonRC.getMobileSession(pAppId):ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

return commonRC
