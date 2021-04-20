---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
-- Issue:https://github.com/smartdevicelink/sdl_core/issues/3648

-- Description: Check that PTU is successfully performed via HMI without mobile connection

-- In case:
-- 1. No app is connected
-- 2. And 'Exchange after X days' PTU trigger occurs
-- SDL does:
--   a) Start new PTU sequence through HMI:
--      - Send 'BC.PolicyUpdate' request to HMI
--      - Send 'SDL.OnStatusUpdate(UPDATE_NEEDED)' notification to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local days = 30

--[[ Local Functions ]]
local function updFunc(pTbl)
  pTbl.policy_table.module_config.exchange_after_x_days = days
end

local function setPtExchangedXDaysAfterEpochInDB()
  local daysAfterEpoch = math.floor(os.time() / 86400) - days - 1
  local dbQuery = '\"UPDATE module_meta SET pt_exchanged_x_days_after_epoch = '
    .. daysAfterEpoch .. ' WHERE rowid = 1;\"'
  common.updatePolicyDB(dbQuery)
end

local function ignitionOn()
  common.startWithOutConnectMobile()
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
      common.hmi():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI PTU Successful", common.ptuViaHMI, { updFunc })
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Set SystemDaysAfterEpoch in the past in policy DB", setPtExchangedXDaysAfterEpochInDB)
runner.Step("New HMI PTU on Days trigger", ignitionOn)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
