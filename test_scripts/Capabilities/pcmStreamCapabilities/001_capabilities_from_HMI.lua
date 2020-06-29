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

--[[ Local Functions ]]
local function getCaseName(pCaseTable)
  local name = "TC == "
  local isFirst = true
  for k, v in pairs(pCaseTable) do
    if isFirst then isFirst = false else name = name .. ", " end
    name = name .. tostring(k) .. ": " .. tostring(v)
  end
  name = name .. " ==\n"
  return name
end

--[[ Scenario ]]
for _, data in common.spairs(common.getPcmStreamCapabilitiesValues()) do
  common.Title(getCaseName(data))
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)

  common.Title("Test")
  common.Step("Set HMI Capabilities", common.setHMICapabilities, { data })
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { common.hmiDefaultCapabilities })
  common.Step("App registration", common.registerApp, { data })

  common.Title("Postconditions")
  common.Step("Close mobile session", common.closeSession)
  common.Step("Stop SDL", common.postconditions)
end
