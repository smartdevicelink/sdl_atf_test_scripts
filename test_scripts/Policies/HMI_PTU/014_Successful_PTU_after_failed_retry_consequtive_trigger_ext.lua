---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Successful 2nd HMI PTU if it's triggered after failed retry for the 1st PTU
-- Note: script is applicable for EXTERNAL_PROPRIETARY policy flow
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App_1 is registered
-- SDL does:
--  - start PTU sequence
--
-- Steps:
-- 1) HMI or App_1 don't provide PTU update
-- SDL does:
--  - finish PTU retry sequence with `UPDATE_NEEDED` status
-- 2) App_2 is registered
-- SDL does:
--  - start new PTU sequence
-- 3) HMI provides valid PTU update
-- SDL does:
--  - finish 2nd PTU sequence successfully with `UP_TO_DATE` status
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local secondsBetweenRetries = { 1, 2 } -- in sec
local timeout_after_x_seconds = 4 -- in sec
local expNumOfOnSysReq = #secondsBetweenRetries + 1
local numOfOnSysReq = 0

--[[ Local Functions ]]
local function updatePreloadedTimeout(pTbl)
  pTbl.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
  pTbl.policy_table.module_config.seconds_between_retries = secondsBetweenRetries
end

local function sendOnSystemRequest()
  if numOfOnSysReq == expNumOfOnSysReq then return end
  common.hmi():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = "files/ptu.json" })
  common.log("HMI->SDL:", "BC.OnSystemRequest")
  numOfOnSysReq = numOfOnSysReq + 1
end

local function unsuccessfulPTUviaMobile()
  local timeout = 60000
  common.mobile():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Do(function()
      common.log("SDL->MOB:", "OnSystemRequest")
    end)
  :Times(expNumOfOnSysReq)
  :Timeout(timeout)

  local exp = {
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" }
  }
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", unpack(exp))
  :Times(#exp)
  :Timeout(timeout)
  :Do(function(_, data)
      common.log("SDL->HMI:", "SDL.OnStatusUpdate(" .. data.params.status .. ")")
      if data.params.status == "UPDATE_NEEDED" then
        common.runAfter(sendOnSystemRequest, 1000)
      end
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update with retry parameters", common.updatePreloaded, { updatePreloadedTimeout })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App1", common.registerApp, { 1 })
runner.Step("Unsuccessful PTU via a HMI", common.unsuccessfulPTUviaHMI)
runner.Step("Unsuccessful PTU via a mobile device", unsuccessfulPTUviaMobile)
runner.Step("Check PTU status UPDATE_NEEDED", common.checkPTUStatus, { "UPDATE_NEEDED" })

runner.Step("Register App2", common.registerApp, { 2 })
runner.Step("Successful PTU via HMI", common.ptuViaHMI)
runner.Step("Check PTU status UP_TO_DATE", common.checkPTUStatus, { "UP_TO_DATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
