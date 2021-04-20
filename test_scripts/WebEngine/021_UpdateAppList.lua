---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the UpdateAppList request to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with new application properties 'enabled' = false of the policyAppID1 to SDL
--  a. SDL sends successful response to HMI
--  b. SDL does not send an UpdateAppList message with policyAppID1 to HMI
-- 2. HMI sends BC.SetAppProperties request with modified app properties 'enabled' = true of the policyAppID1 to SDL
--  a. SDL sends successful response to HMI
--  b. SDL sends an UpdateAppList message with policyAppID1 to HMI
-- 3. HMI sends BC.SetAppProperties request with modified app properties 'enabled' = false of the policyAppID1 to SDL
--  a. SDL sends successful response to HMI
--  b. SDL does not send an UpdateAppList message with policyAppID1 to HMI
-- 4. HMI sends BC.SetAppProperties request with app properties 'enabled' = true of the policyAppID2 to SDL
--  a. SDL sends successful response to HMI
--  b. SDL sends an UpdateAppList message with policyAppID2 and without policyAppID1 to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Functions ]]
local expected = 1

--[[ Local Functions ]]
local function setAppProperties(pAppId, pEnabled, pTimes, pExpNumOfApps)
  local webAppProperties = {
    nicknames = { "Test Web Application_" .. pAppId },
    policyAppID = "000000" .. pAppId,
    enabled = pEnabled,
    transportType = "WS",
    hybridAppPreference = "CLOUD"
  }
  common.setAppProperties(webAppProperties)
  common.checkUpdateAppList(webAppProperties.policyAppID, pTimes, pExpNumOfApps)
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("UpdateAppList on setAppProperties for policyAppID1: enabled = false",
  setAppProperties, { 1, false })
common.Step("UpdateAppList on setAppProperties for policyAppID1: modified enabled from false to true",
  setAppProperties, { 1, true, expected, 1 })
common.Step("UpdateAppList on setAppProperties for policyAppID1: modified enabled from true to false",
  setAppProperties, { 1, false, expected, 0 })
common.Step("UpdateAppList on setAppProperties for policyAppID2: enabled = true",
  setAppProperties, { 2, true, expected, 1 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
