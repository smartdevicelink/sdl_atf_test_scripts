---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3882
---------------------------------------------------------------------------------------------------
-- Description: SDL does not send `UI.ChangeRegistration` with updated HMI type after PTU with the same HMI type
--  for registered app
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered with <HMI type 1>
-- 3. PTU is performed with <HMI type 1>  for registered app id
-- SDL does:
-- - not send UI.ChangeRegistration("appHMIType" = { <HMI type 1> }) to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3882/common')

--[[ Local Functions ]]
local function changeRegistration(pHMItype)
  common.getHMIConnection():ExpectRequest("UI.ChangeRegistration", { appHMIType = pHMItype })
  :Times(0)
end

--[[ Scenario ]]
for tc, v in ipairs(common.tcsActivation) do
  common.Title("Test case [" .. string.format("%02d", tc) .. "]: " .. " PTU with the same HMI type " ..
    tostring(v.name))
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.appRegistration, { { common.hmiTypes[1] } })
  if v.isActive == true then
    common.Step("Activate App", common.activateApp)
  end

  common.Title("Test")
  common.Step("Policy table update", common.ptu, { { common.hmiTypes[1] }, changeRegistration })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
