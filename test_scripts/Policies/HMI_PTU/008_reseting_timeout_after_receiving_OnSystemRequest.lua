---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md

-- Description: Reseting of the SDL timeout after receiving onSystemRequest notification

-- In case:
-- 1. timeout_after_x_seconds is set to 6 seconds in preloaded file
-- 2. Mobile app is registered and activated
-- 3. PTU via HMI is started
-- SDL does:
--   a. start timeout_after_x_seconds timeout
-- 4. In some time before timeout_after_x_seconds is finishes SDL receives onSystemRequest(PROPRIETARY) from HMI
-- SDL does:
--   a. renew PTU timeout to timeout_after_x_seconds after receiving notification
-- 5. timeout_after_x_seconds timeout is expired
-- 6. SDL sends SDL.OnStatusUpdate(UPDATE_NEEDED) to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local timeout_after_x_seconds = 6 -- in sec
local inaccuracy = 500 -- in msec

--[[ Local Functions ]]
local function updatePreloadedTimeout(pTbl)
  pTbl.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
end

local function resetTimeoutAfterOnSystemRequest()
  local systemRequestTime = timestamp()
  common.hmi():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = "files/ptu.json" })
  common.mobile():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" }):Times(AtLeast(1))
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }):Times(AtLeast(1))
  :ValidIf(function(e)
    if e.occurences == 1 then
      local updateNeddedTime = timestamp()
      local passedTime = updateNeddedTime - systemRequestTime -- in msec
      -- timeout_after_x_seconds*1000 - convert timeout_after_x_seconds from sec to msec
      if passedTime > timeout_after_x_seconds*1000 + inaccuracy or
        passedTime < timeout_after_x_seconds*1000 - inaccuracy then
        return false , "SDL timer was not updated. Expected time " .. timeout_after_x_seconds*1000 .. " ms. Actual time "
        .. passedTime
      end
    end
    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update with retry parameters", common.updatePreloaded, { updatePreloadedTimeout })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)

runner.Title("Test")
runner.Step("Unsuccessful PTU via a HMI", common.unsuccessfulPTUviaHMI)
runner.Step("Reseting timer after onSystemRequest", resetTimeoutAfterOnSystemRequest)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
