---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3882
---------------------------------------------------------------------------------------------------
-- Description: SDL sends `UI.ChangeRegistration` with updated HMI type after PTU with replaced HMI type
-- in default section for registered app
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered with <HMI type 1>
-- 3. PTU is performed with <HMI type 2> for default permissions
-- SDL does:
-- - send UI.ChangeRegistration("appHMIType" = { <HMI type 2> }) to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3882/common')

--[[ Local Variables ]]
local useDefaultFunc = nil

--[[ Local Functions ]]
local function updFuncWraper(pHMItype)
  local function updFunc(pTbl)
    pTbl.policy_table.app_policies.default.AppHMIType = pHMItype
    pTbl.policy_table.app_policies[common.getPolicyAppId()] = "default"
  end
  return updFunc
end

--[[ Scenario ]]
for tc, v in ipairs(common.tcsActivation) do
  common.Title("Test case [" .. string.format("%02d", tc) .. "]: " .. " PTU with different HMI type " ..
    tostring(v.name))
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.appRegistration, { { common.hmiTypes[1] } })
  if v.isActive == true then
    common.Step("Activate App", common.activateApp)
  end

  common.Title("Test")
  common.Step("Policy table update", common.ptu, { { common.hmiTypes[2] }, useDefaultFunc, updFuncWraper })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
