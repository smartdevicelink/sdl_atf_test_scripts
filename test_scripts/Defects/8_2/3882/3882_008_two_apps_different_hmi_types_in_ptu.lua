---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3882
---------------------------------------------------------------------------------------------------
-- Description: SDL sends `UI.ChangeRegistration` with updated HMI type after PTU with replaced HMI type
--  for several registered apps
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. App1 is registered with <HMI type 1>
-- 3. App2 is registered with <HMI type 2>
-- 4. App1 is activated
-- 5. PTU is performed with <HMI type 3> for both registered app ids
-- SDL does:
-- - send two UI.ChangeRegistration("appHMIType" = { <HMI type 3> }) to HMI for each app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3882/common')

--[[ Local Functions ]]
local function updFuncWraper(pHMItype)
  local function updFunc(pTbl)
    pTbl.policy_table.app_policies[common.getPolicyAppId(1)].AppHMIType = pHMItype
    pTbl.policy_table.app_policies[common.getPolicyAppId(2)].AppHMIType = pHMItype
  end
  return updFunc
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App 2", common.registerSecondAppWOptu, { { common.hmiTypes[2] } })
common.Step("Register App 1", common.appRegistration, { { common.hmiTypes[1] } })
common.Step("Activate App 1", common.activateApp)

common.Title("Test")
common.Step("Policy table update", common.ptu,
  { { common.hmiTypes[3] }, common.changeRegistration2apps, updFuncWraper })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

