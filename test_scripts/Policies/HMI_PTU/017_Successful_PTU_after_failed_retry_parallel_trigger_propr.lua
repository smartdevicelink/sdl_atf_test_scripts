---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Successful 2nd HMI PTU if it's triggered within failed retry for the 1st PTU
-- Note: script is applicable for PROPRIETARY policy flow
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App_1 is registered
-- SDL does:
--  - start PTU sequence
--
-- Steps:
-- 1) HMI or App_1 don't provide PTU update
-- 2) App_2 is registered within PTU retry sequence
-- SDL does:
--  - postpone new PTU sequence until the previous one is finished
-- 3) App_1 doesn't provide PTU update
-- SDL does:
--  - finish 1st PTU retry sequence with `UPDATE_NEEDED` status
--  - start new PTU sequence with `UPDATE_NEEDED` status and send `BC.PolicyUpdate` request to HMI
-- 4) HMI provides valid PTU update
-- SDL does:
--  - finish 2nd PTU sequence successfully with `UP_TO_DATE` status
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY" } } }

--[[ Local Variables ]]
local secondsBetweenRetries = { 1, 2 } -- in sec
local timeout_after_x_seconds = 4 -- in sec

--[[ Local Functions ]]
local function updatePreloadedTimeout(pTbl)
  pTbl.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
  pTbl.policy_table.module_config.seconds_between_retries = secondsBetweenRetries
end

local function unsuccessfulPTUviaMobile()
  local timeout = 60000
  common.mobile():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Do(function()
      common.log("SDL->MOB:", "OnSystemRequest")
    end)
  :Times(2)
  :Timeout(timeout)

  local isBCPUReceived = false
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
      isBCPUReceived = true
      common.hmi():SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  local exp = {
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATE_NEEDED" }, -- new PTU sequence
    { status = "UPDATING" }
  }
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", unpack(exp))
  :Times(#exp)
  :Timeout(timeout)
  :Do(function(e, data)
      common.log("SDL->HMI:", "SDL.OnStatusUpdate(" .. data.params.status .. ")")
      if e.occurences == 2 then
        common.checkPTUStatus("UPDATING")
      end
      if e.occurences == 3 then
        common.registerNoPTU(2)
        common.log("SDL->MOB2:", "RAI2")
      end
    end)
    :ValidIf(function(e)
      if e.occurences == #exp - 1 and isBCPUReceived == true then
        return false, "BC.PolicyUpdate is sent before new PTU sequence"
      end
      if e.occurences == #exp and isBCPUReceived == false then
        return false, "BC.PolicyUpdate is not sent within new PTU sequence"
      end
      return true
    end)
end

local function ptuViaHMI()
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate"):Times(0)
  common.ptuViaHMI()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update with retry parameters", common.updatePreloaded, { updatePreloadedTimeout })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.register, { 1 })
runner.Step("Activate App", common.activateApp, { 1 })
runner.Step("Unsuccessful PTU via a HMI", common.unsuccessfulPTUviaHMI)
runner.Step("Unsuccessful PTU via a mobile device", unsuccessfulPTUviaMobile)

runner.Step("Successful PTU via HMI", ptuViaHMI)
runner.Step("Check PTU status UP_TO_DATE", common.checkPTUStatus, { "UP_TO_DATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
