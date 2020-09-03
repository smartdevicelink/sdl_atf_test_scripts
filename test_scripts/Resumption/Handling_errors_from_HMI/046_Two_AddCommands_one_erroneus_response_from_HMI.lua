---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check data resumption is failed for a few commands in case if HMI responds with <erroneous> result code
-- to at least one request from SDL
--
-- In case:
-- 1. VR is supported by HMI
-- 2. App successfully added 2 VR commands by using 'AddCommand' requests: Cmd1 and Cmd2
-- 3. Unexpected disconnect/IGN_OFF and Reconnect/IGN_ON are performed
-- 4. App re-registers with actual HashId
-- SDL does:
--  - start resumption process for App
--  - send UI.AddCommand, VR.AddCommand, UI.SetGlobalProperties, TTS.SetGlobalProperties requests to HMI
-- 5. HMI responds with error for 'VR.AddCommand(Cmd2)' and with success for others
-- SDL does:
--  - process responses from HMI
--  - remove already restored data
--  - send UI.DeleteCommand(Cmd1, Cmd2), VR.DeleteCommand(Cmd1) requests to HMI
--  - send UI.SetGlobalProperties(<default>), TTS.SetGlobalProperties(<default>) requests to HMI
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function addCommand(pCmdId)
  local params = {
    cmdID = pCmdId,
    vrCommands = { "vrCommand" .. pCmdId },
    menuParams = { menuName = "menu" .. pCmdId }
  }
  local cid = common.getMobileSession():SendRPC("AddCommand", params)
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.hashId[1] = data.payload.hashID
    end)
end

local function checkResumption()
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      common.log(data.method, data.params.cmdID)
      common.log(data.method, data.params.cmdID, ": SUCCESS")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.log(data.method, data.params.cmdID)
      if data.params.cmdID == 2 then
        common.log(data.method, data.params.cmdID, ": GENERIC_ERROR")
        common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
      else
        common.log(data.method, data.params.cmdID, ": SUCCESS")
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("UI.DeleteCommand")
  :Do(function(_, data)
      common.log(data.method, data.params.cmdID)
      common.log(data.method, data.params.cmdID, ": SUCCESS")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("VR.DeleteCommand")
  :Do(function(_, data)
      common.log(data.method, data.params.cmdID)
      common.log(data.method, data.params.cmdID, ": SUCCESS")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_, data)
      if data.params.cmdID == 2 then
        return false, "Request for cmdID=2 is unexpected"
      end
      return true
    end)
  :Times(1)

  local uiSGP_reset = common.getGlobalPropertiesResetData(1, "UI")
  uiSGP_reset.menuTitle = nil
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", {}, uiSGP_reset)
  :Do(function(_, data)
      common.log(data.method)
      common.log(data.method, ": SUCCESS")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(2)

  local ttsSGP_reset = common.getGlobalPropertiesResetData(1, "TTS")
  ttsSGP_reset.timeoutPrompt = nil
  common.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", {}, ttsSGP_reset)
  :Do(function(_, data)
      common.log(data.method)
      common.log(data.method, ": SUCCESS")
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(2)
end

local function reRegisterApp()
  common.openRPCservice()
  :Do(function()
      common.log("RPC Service started")
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      :Do(function(exp, data)
          common.log("BC.OnAppRegistered")
          common.setHMIAppId(data.params.application.appID, exp.occurences)
          common.sendOnSCU(0, exp.occurences)
        end)
      common.reRegisterAppCustom(1, "RESUME_FAILED", 0)
      :Do(function()
          common.expOnHMIStatus(1, "FULL")
        end)
      checkResumption()
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app", common.registerAppWOPTU)
runner.Step("Activate app", common.activateApp)
runner.Step("Add Command 2", addCommand, { 2 })
runner.Step("Add Command 1", addCommand, { 1 })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption", reRegisterApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
