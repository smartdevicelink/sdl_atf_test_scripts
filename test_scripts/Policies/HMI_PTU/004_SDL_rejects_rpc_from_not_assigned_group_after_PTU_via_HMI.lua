---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
--
-- Description: Check that SDL rejects RPC from the group not assigned to the App after PTU via HMI was performed
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. App is registered
-- 3. PTU via HMI was performed successfully
-- 4. App is activated
--
-- Steps:
-- 1) App sends GetVehicleData RPC from the group not assigned to it
-- SDL does:
--   a) send GetVehicleData( resultCode = DISALLOWED ) response to the App
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[Local Functions]]
local function sendProhibitedRPC()
  local cid = common.mobile():SendRPC("GetVehicleData", { fuelLevel = true })
  common.mobile():ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU via HMI", common.ptuViaHMI)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send not allowed GetVehicleData RPC from the App", sendProhibitedRPC)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
