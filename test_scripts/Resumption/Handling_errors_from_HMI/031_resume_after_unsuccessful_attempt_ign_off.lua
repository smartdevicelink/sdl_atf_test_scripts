---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- Check there is no 2nd data resumption after failed the 1st one
-- (Ignition Off/On scenario)
--
-- In case:
-- 1. AddSubMenu related to resumption is sent by app
-- 2. IGN_OFF and IGN_ON are performed
-- 3. App re-registers with actual HashId
-- SDL does:
--  - start resumption process
--  - send UI.AddSubMenu request to HMI
-- 4. HMI responds with error resultCode to UI.AddSubMenu request
-- SDL does:
--  - respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
--  - generate new HashId
-- 5. App does not send any new RPC related to resumption
-- 6. IGN_OFF and IGN_ON are performed
-- 7. App re-registers with new actual HashId
-- SDL does:
--  - start resumption process
--  - not send UI.AddSubMenu request to HMI
--  - not restore persistent data
--  - respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to mobile application
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
  common.reRegisterAppResumeFailed(pAppId, ...)
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
runner.Step("IGNITION OFF", common.ignitionOff)
runner.Step("IGNITION ON", common.start)
runner.Step("Reregister App resumption " .. RPC, reRegisterApp,
  { 1, common.checkResumptionData, common.resumptionFullHMILevel, RPC, "UI"})
runner.Step("IGNITION OFF", common.ignitionOff)
runner.Step("IGNITION ON", common.start)
runner.Step("Reregister App resumption without data", common.reRegisterAppSuccess,
  { 1, checkResumptionData, common.resumptionFullHMILevel })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
