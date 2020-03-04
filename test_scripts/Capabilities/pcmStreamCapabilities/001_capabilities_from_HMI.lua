---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0252-Aligning-HMI-and-MOBILE-API-for-pcmStreamCapabilities.md
--
-- Description: Applying the pcmStreamCapabilities received from HMI
--
-- In case:
-- 1) HMI sends UI.GetCapabilities(pcmStreamCapabilities)
-- SDL does:
--   a) apply the pcmStreamCapabilities received from HMI
-- 2) Mobile app is registered
-- SDL does:
--   a) send RAI response with pcmStreamCapabilities received from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Capabilities/pcmStreamCapabilities/commonPcmStreamCapabilities")

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Set HMI Capabilities", common.setHMICapabilities, { common.pcmStreamCapabilitiesValue })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
common.Step("App registration", common.registerApp, { common.pcmStreamCapabilitiesValue })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
