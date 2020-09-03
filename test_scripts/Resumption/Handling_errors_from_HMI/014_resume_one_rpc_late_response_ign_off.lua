---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check data resumption is failed in case if HMI responds with SUCCESS result code to request from SDL
-- after default timeout expires (Ignition Off/On scenario)
--
-- In case:
-- 1. <Rpc_n> related to resumption is sent by app
-- 2. IGN_OFF and IGN_ON are performed
-- 3. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send <Rpc_n> request to HMI
-- 4. HMI responds with SUCCESS resultCode to <Rpc_n> request when default timeout (10s) expires
-- SDL does:
--  - ignore late response
--  - not send revert <Rpc_n> request to HMI
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
--    when default timeout expires
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Functions ]]
function common.sendResponse(pData, pErrorRespInterface, pCurrentInterface)
  local function response()
    common.getHMIConnection():SendResponse(pData.id, pData.method, "SUCCESS", common.getSuccessHMIResponseData(pData))
  end
  if pErrorRespInterface ~= nil and pErrorRespInterface == pCurrentInterface then
    common.run.runAfter(response, 11000)
  else
    response()
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for k, value in common.pairs(common.rpcs) do
  for _, interface in common.pairs(value) do
    runner.Title("Rpc " .. k .. " late response to interface " .. interface)
    runner.Step("Register app", common.registerAppWOPTU)
    runner.Step("Activate app", common.activateApp)
    runner.Step("Add " .. k, common[k])
    runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
    runner.Step("Connect mobile", common.connectMobile)
    runner.Step("Reregister App resumption " .. k, common.reRegisterAppResumeFailed,
      { 1, common.checkResumptionData, common.resumptionFullHMILevel, k, interface, 15000})
    runner.Step("Unregister App", common.unregisterAppInterface)
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
