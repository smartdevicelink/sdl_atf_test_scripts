---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3715
---------------------------------------------------------------------------------------------------
-- Description: SDL only accepts PTU from application which was sent OnSystemRequest
--
-- Steps:
-- 1. Core and HMI are started
-- 2. An application is registered
-- 3. Core sends OnStatusUpdate UPDATING
-- 4. Two Applications register, OnSystemRequest is sent to one of them
-- SDL does:
--  - reject the PTU, responding success false REJECTED
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local SDL = require('SDL')
local utils = require('user_modules/utils')
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "HTTP" } } }

--[[ Local Variables ]]

--[[ Local Functions ]]
local function ptuWrongApp()
  local ptuFileName = os.tmpname()
  local ptuTable = common.getPTUFromPTS()
  for i, _ in pairs(common.mobile.getApps()) do
    ptuTable.policy_table.app_policies[common.app.getPolicyAppId(2)] = common.ptu.getAppData(2)
  end
  utils.tableToJsonFile(ptuTable, ptuFileName)
  local corId3 = common.mobile.getSession(1):SendRPC("SystemRequest", { requestType = "PROPRIETARY" }, ptuFileName)
  common.mobile.getSession(1):ExpectResponse(corId3, { success = false, resultCode = "REJECTED" })
  :Do(function() os.remove(ptuFileName) end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerAppWOPTU, { 2 })

runner.Title("Test")
runner.Step("PTU from the wrong app", ptuWrongApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
