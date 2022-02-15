---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3715
---------------------------------------------------------------------------------------------------
-- Description: SDL rejects PTUs when not UPDATING
--
-- Steps:
-- 1. Core and HMI are started
-- 2. Application 1 connections and activates
-- 3. PTU is completed successfully and status is UP_TO_DATE
-- 4. App 1 sends SystemRequest PROPRIETARY
-- SDL does:
--  - reject the PTU, responding success false REJECTED
-- 5. Application 2 registers and is activated
-- 6. App 2 sends SystemRequest PROPRIETARY
-- SDL does:
--  - reject the PTU, responding success false REJECTED
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local SDL = require('SDL')
local utils = require('user_modules/utils')
local consts = require('user_modules/consts')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

--[[ Local Functions ]]
local function checkPTUStatus(pExpStatus)
  local cid = common.hmi.getConnection():SendRequest("SDL.GetStatusUpdate")
  common.hmi.getConnection():ExpectResponse(cid, { result = { status = pExpStatus }})
end

local function attemptUnpromptedPTU(appId)
  local ptuFileName = os.tmpname()
  local ptuTable = common.getPTUFromPTS()
  for i, _ in pairs(common.mobile.getApps()) do
    ptuTable.policy_table.app_policies[common.app.getPolicyAppId(i)] = common.ptu.getAppData(i)
  end
  utils.tableToJsonFile(ptuTable, ptuFileName)

  local mobile = common.getMobileSession(appId)

  local cid = 0
  local policyMode = SDL.buildOptions.extendedPolicy
  if policyMode == "HTTP" then
    cid = mobile:SendRPC("SystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate" }, ptuFileName)
  else
    cid = mobile:SendRPC("SystemRequest", { requestType = "PROPRIETARY" }, ptuFileName)
  end

  mobile:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
  :Do(function() os.remove(ptuFileName) end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Successful PTU via Mobile", common.ptu.policyTableUpdate)
runner.Step("Check PTU status UP_TO_DATE", checkPTUStatus, { "UP_TO_DATE" })

runner.Title("Test")
runner.Step("App 1 attempt unprompted PTU", attemptUnpromptedPTU, { 1 })
runner.Step("Register App 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("App 2 attempt unprompted PTU 2", attemptUnpromptedPTU, { 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
