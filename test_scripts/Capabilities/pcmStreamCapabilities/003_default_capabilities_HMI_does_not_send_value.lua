---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0252-Aligning-HMI-and-MOBILE-API-for-pcmStreamCapabilities.md
--
-- Description: Applying the default pcmStreamCapabilities from hmi_capabilities.json
--   in case SDL does not receive the pcmStreamCapabilities from HMI
--
-- In case:
-- 1) HMI sends UI.GetCapabilities without pcmStreamCapabilities value
-- SDL does:
--   a) apply the default capabilities from hmi_capabilities.json
-- 2) Mobile app is registered
-- SDL does:
--   a) send RAI response with default pcmStreamCapabilities value from hmi_capabilities.json
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Capabilities/pcmStreamCapabilities/commonPcmStreamCapabilities")

--[[ Local Variables ]]
local pcmStreamCapabilitiesValue = nil

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Set HMI Capabilities", common.setHMICapabilities, { pcmStreamCapabilitiesValue })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("App registration", common.registerApp, { common.defaultPcmStreamCapabilities })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
