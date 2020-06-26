---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the UpdateAppList request to HMI on start
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with new application properties 'enabled' = false of the policyAppID1 to SDL
--  a. SDL sends successful response to HMI
-- 2. Ignition off/on are performed
--  a. SDL does not send an UpdateAppList message with policyAppID1 to HMI
-- 3. HMI sends BC.SetAppProperties request with modified app properties 'enabled' = true of the policyAppID1 to SDL
--  a. SDL sends successful response to HMI
-- 4. Ignition off/on are performed
--  a. SDL sends an UpdateAppList message with policyAppID1 to HMI
-- 5. HMI sends BC.SetAppProperties request with new application properties 'enabled' = false of the policyAppID2 to SDL
--  a. SDL sends successful response to HMI
-- 6. Ignition off/on are performed
--  b. SDL sends an UpdateAppList message with policyAppID1 and without policyAppID2 to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Functions ]]
local expected = 1
local notExpected = 0

--[[ Local Functions ]]
local function setAppProperties(pAppId, pEnabled)
  local webAppProperties = {
    nicknames = { "Test Web Application_" .. pAppId },
    policyAppID = "000000" .. pAppId,
    enabled = pEnabled,
    transportType = "WS",
    hybridAppPreference = "CLOUD"
  }
  common.setAppProperties(webAppProperties)
end

local function start(pAppID, pTimes, pExpNumOfApps)
  local policyAppID = "000000" .. tostring(pAppID)
  common.checkUpdateAppList(policyAppID, pTimes, pExpNumOfApps)
  common.start()
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request for policyAppID1: enabled = false", setAppProperties, { 1, false })
common.Step("IgnitionOff", common.ignitionOff)
common.Step("UpdateAppList on start: policyAppID1", start, { 1, notExpected})

common.Step("SetAppProperties request for policyAppID1: modified enabled from false to true", setAppProperties, { 1, true })
common.Step("IgnitionOff", common.ignitionOff)
common.Step("UpdateAppList on start: policyAppID1", start, { 1, expected, 1})

common.Step("SetAppProperties request for policyAppID2:  enabled = false", setAppProperties, { 2, false })
common.Step("IgnitionOff", common.ignitionOff)
common.Step("UpdateAppList on start: policyAppID1", start, { 1, expected, 1})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
