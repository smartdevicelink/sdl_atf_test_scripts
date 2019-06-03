---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- 1. AddSubMenu for resumption is added by app
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App reregisters with actual HashId
-- 4. UI.AddSubMenu request is sent from SDL to HMI during resumption
-- 5. HMI responds with error_n resultCode to UI.AddSubMenu request
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local resultCodes = {
  "UNSUPPORTED_REQUEST",
  "UNSUPPORTED_RESOURCE",
  "DISALLOWED",
  "REJECTED",
  "ABORTED",
  "IGNORED",
  "RETRY",
  "IN_USE",
  "DATA_NOT_AVAILABLE",
  "TIMED_OUT",
  "INVALID_DATA",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "DUPLICATE_NAME",
  "APPLICATION_NOT_REGISTERED",
  "WRONG_LANGUAGE",
  "OUT_OF_MEMORY",
  "TOO_MANY_PENDING_REQUESTS",
  "NO_APPS_REGISTERED",
  "NO_DEVICES_CONNECTED",
  "USER_DISALLOWED",
  "TRUNCATED_DATA",
  "READ_ONLY"
}

--[[ Local Functions ]]
local function reRegisterApp(pAppId, pErrorCode)
  local mobSession = common.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = common.cloneTable(common.getConfigAppParams(pAppId))
      params.hashID = common.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = common.getConfigAppParams(pAppId).appName }
        })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu",common.resumptionData[pAppId].addSubMenu.UI)
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, pErrorCode, "info message")
    end)

  common.resumptionFullHMILevel(pAppId)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for _, code in pairs(resultCodes) do
  runner.Step("Register app", common.registerAppWOPTU)
  runner.Step("Activate app", common.activateApp)
  runner.Step("Add addSubMenu", common.addSubMenu)
  runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
  runner.Step("Connect mobile", common.connectMobile)
  runner.Step("Reregister App resumption with error code " .. code, reRegisterApp, { 1, code })
  runner.Step("Unregister App", common.unregisterAppInterface)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
