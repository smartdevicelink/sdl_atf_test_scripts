---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3882
---------------------------------------------------------------------------------------------------
-- Description: SDL sends `UI.ChangeRegistration` with updated HMI types after PTU with additional HMI type
--  for registered app
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered with <HMI type 1>
-- 3. PTU is performed with <HMI type 1>, <HMI type 2>  for registered app id
-- SDL does:
-- - send UI.ChangeRegistration("appHMIType" = { <HMI type 1>, <HMI type 2> }) to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3882/common')

--[[ Scenario ]]
for tc, v in ipairs(common.tcsActivation) do
  common.Title("Test case [" .. string.format("%02d", tc) .. "]: " .. " PTU with additional HMI type " ..
    tostring(v.name))
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.appRegistration, { { common.hmiTypes[1] } })
  if v.isActive == true then
    common.Step("Activate App", common.activateApp)
  end

  common.Title("Test")
  common.Step("Policy table update", common.ptu, { { common.hmiTypes[1], common.hmiTypes[2] } })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
