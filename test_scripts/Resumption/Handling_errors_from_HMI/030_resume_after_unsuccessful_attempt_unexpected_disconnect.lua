---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- In case:
-- 1. AddSubMenu for resumption is added by app
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App reregisters with actual HashId
-- 4. AddSubMenu request is sent from SDL to HMI during resumption
-- 5. HMI responds with error resultCode to UI.AddSubMenu request
-- 6. SDL respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
-- 7. Unexpected disconnect and reconnect are performed
-- 8. App reregisters with actual HashId
-- SDL does:
-- 1. SDL respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to mobile application and does not resume any persistent data
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variable ]]
local RPC = "addSubMenu"

-- [[ Local Function ]]
local function checkResumptionData()
  EXPECT_HMICALL("UI.AddSubMenu")
  :Times(0)
  common.wait(3000)
end

local function reRegisterApp(pAppId, ...)
  common.reRegisterApp(pAppId, ...)
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.hashId[pAppId] = data.payload.hashID
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app", common.registerAppWOPTU)
runner.Step("Activate app", common.activateApp)
runner.Step("Add " .. RPC, common[RPC])
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption " .. RPC, reRegisterApp,
  { 1, common.checkResumptionData, common.resumptionFullHMILevel, RPC, "UI"})
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption without data", common.reRegisterAppSuccess,
  { 1, checkResumptionData, common.resumptionFullHMILevel })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
