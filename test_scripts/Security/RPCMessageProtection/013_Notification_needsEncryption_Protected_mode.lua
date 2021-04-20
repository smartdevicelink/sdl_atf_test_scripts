---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md

-- Description:
-- Check that after the encryption of RPC service 7 is enabled (encryption is available)
-- SDL sends an encrypted notification if the RPC needs protection.

-- Sequence:
-- 1) The HMI sends RPC notification to the SDL
-- 2) SDL does send encrypted notification to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [001] = { a = true, f = true },
  [002] = { a = nil, f = true }
}

--[[ Local Functions ]]
local function sendOnVD()
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { speed = 1.23 })
  common.getMobileSession():ExpectEncryptedNotification("OnVehicleData", { speed = 1.23 })
end

local function preloadedPTUpdate(pPT)
  local pt = pPT.policy_table
  pt.functional_groupings["Location-1"].user_consent_prompt = nil
  pt.app_policies["default"].groups = { "Base-4", "Location-1" }
  pt.functional_groupings["Base-4"].rpcs.OnVehicleData = pt.functional_groupings["Location-1"].rpcs.OnVehicleData
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]")
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions, { preloadedPTUpdate })
  runner.Step("Preloaded update", common.updatePreloadedPT, { tc.a, tc.f })
  runner.Step("Start SDL, init HMI", common.start)
  runner.Step("Register App", common.registerAppWOPTU)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Subscribe to Vehicle Data ", common.subscribeToVD)
  runner.Step("Start RPC Service protected", common.switchRPCServiceToProtected)

  runner.Title("Test")
  runner.Step("OnVehicleData in protected mode, param for App="..tostring(tc.a)..",for Group="..tostring(tc.f),
    sendOnVD)

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL, restore SDL settings", common.postconditions)
end
