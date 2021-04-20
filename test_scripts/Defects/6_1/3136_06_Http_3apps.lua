---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3136
--
-- Description: Successful 2nd PTU if it's triggered within failed retry for the 1st PTU
-- Note: script is applicable for HTTP policy flow
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App_1 is registered
-- SDL does:
--  - start PTU sequence
--
-- Steps:
-- 1) App_1 doesn't provide PTU update
-- 2) App_2 is registered within PTU retry sequence
-- SDL does:
--  - postpone new PTU sequence until the previous one is finished
-- 3) App_1 still doesn't provide PTU update
-- SDL does:
--  - finish 1st PTU retry sequence with `UPDATE_NEEDED` status
--  - start new PTU sequence with `UPDATE_NEEDED` status
-- 4) Mobile provides valid PTU update
-- SDL does:
--  - finish 2nd PTU sequence successfully with `UP_TO_DATE` status
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "HTTP" } } }

--[[ Local Variables ]]
local secondsBetweenRetries = { 1, 2 }
local timeout_after_x_seconds = 4
local expNumOfOnSysReq = #secondsBetweenRetries + 1

--[[ Local Functions ]]
local function log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(color.magenta, str)
end

local function updatePreloadedTimeout(pTbl)
  pTbl.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
  pTbl.policy_table.module_config.seconds_between_retries = secondsBetweenRetries
end

local function updatePreloaded(pUpdFunc)
  local preloadedTable = common.sdl.getPreloadedPT()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  pUpdFunc(preloadedTable)
  common.sdl.setPreloadedPT(preloadedTable)
end

local function checkPTUStatus(pExpStatus)
  local cid = common.hmi.getConnection():SendRequest("SDL.GetStatusUpdate")
  common.hmi.getConnection():ExpectResponse(cid, { result = { status = pExpStatus }})
end

local function unsuccessfulPTUviaMobile(pNewAppId)
  local timeout = 30000
  common.mobile.getSession():ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
  :Do(function()
      log("SDL->MOB:", "OnSystemRequest")
    end)
  :Times(expNumOfOnSysReq)
  :Timeout(timeout)

  local exp = {
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" },
    { status = "UPDATE_NEEDED" },
    { status = "UPDATE_NEEDED" }, -- new PTU sequence
    { status = "UPDATING" }
  }
  common.hmi.getConnection():ExpectNotification("SDL.OnStatusUpdate", table.unpack(exp))
  :Times(#exp)
  :Timeout(timeout)
  :Do(function(e, data)
      log("SDL->HMI:", "SDL.OnStatusUpdate(" .. data.params.status .. ")")
      if e.occurences == 3 then
        common.app.registerNoPTU(pNewAppId)
        log("SDL->MOB:", "RAI" .. pNewAppId)
      end
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update with retry parameters", updatePreloaded, { updatePreloadedTimeout })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.app.register)
runner.Step("Activate App", common.app.activate)
runner.Step("Unsuccessful PTU via a mobile device", unsuccessfulPTUviaMobile, { 2 })
runner.Step("Unsuccessful PTU via a mobile device", unsuccessfulPTUviaMobile, { 3 })
runner.Step("Successful PTU via Mobile", common.ptu.policyTableUpdate)
runner.Step("Check PTU status UP_TO_DATE", checkPTUStatus, { "UP_TO_DATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
