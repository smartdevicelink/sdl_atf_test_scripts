---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3882
---------------------------------------------------------------------------------------------------
-- Description: SDL sends `UI.ChangeRegistration` with updated HMI type after PTU with replaced HMI type
--  for registered app in case app is NOT activated
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered with <HMI type 1>
-- 3. PTU is performed with <HMI type 2> for registered app id
-- SDL does:
-- - send UI.ChangeRegistration("appHMIType" = { <HMI type 2> }) to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3882/common')

--[[ Scenario ]]
for tc, v in ipairs(common.hmiTypes) do
  common.Title("Test case [" .. string.format("%02d", tc) .. "]: " .. "App with type '" .. tostring(v) .. "'")
  for _, subv in ipairs(common.hmiTypes) do
    if v ~= subv then
      common.Title("Preconditions")
      common.Step("Clean environment", common.preconditions)
      common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
      common.Step("Register App", common.appRegistration, { { v } })

      common.Title("Update with '" .. tostring(subv) .. "' type for app with '" .. tostring(v) .. "' type")
      common.Step("Policy table update", common.ptu, { { subv } })

      common.Title("Postconditions")
      common.Step("Stop SDL", common.postconditions)
    end
  end
end

