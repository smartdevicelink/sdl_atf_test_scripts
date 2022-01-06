---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/3804
---------------------------------------------------------------------------------------------------
-- Description:
-- Validate hmiCapabilities navigation, phoneCall and videoStreaming in RAI response 
--
-- Precondition:
-- 1) HMI capabilities cache file (hmi_capabilities_cache.json) exists:
--  - with "hmiCapabilities": <hmiCapabilities> parameter
--  - without the "systemCapabilities":<systemCapabilities> parameter
-- 2) SDL, HMI, Mobile session are started
--
-- Test:
-- 1) App sends RegisterAppInterface request
-- SDL does:
--  - send RAI response with the <hmiCapabilities> parameter from HMI capabilities cache file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color
local SDL = require('SDL')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local missingCapability = {
  [1] = "navigationCapability",
  [2] = "phoneCapability",
  [3] = "videoStreamingCapability"
}

--[[ Local Functions ]]
local function ignitionOff()
  local isOnSDLCloseSent = false
  common.hmi.getConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.hmi.getConnection():SendNotification("BasicCommunication.OnExitAllApplications",
        { reason = "IGNITION_OFF" })
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          isOnSDLCloseSent = true
          SDL.DeleteFile()
        end)
    end)
  common.run.wait(3000)
  :Do(function()
      if isOnSDLCloseSent == false then utils.cprint(color.magenta, "BC.OnSDLClose was not sent") end
      for i = 1, common.mobile.getAppsCount() do
        common.mobile.deleteSession(i)
      end
      StopSDL()
    end)
end

local function getHMIParams(pMissingCapability)
  local params = hmi_values.getDefaultHMITable()
  params.UI.GetCapabilities.params.hmiCapabilities = { navigation = true, phoneCall = true, videoStreaming = true }
  params.UI.GetCapabilities.params.systemCapabilities[pMissingCapability] = nil
  return params
end

local function reRegisterApp()
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", common.app.getParams())
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS",
        hmiCapabilities = {
          appServices = true,
          displays = true,
          driverDistraction = true,
          navigation = true,
          phoneCall = true,
          remoteControl = true,
          seatLocation = true,
          videoStreaming = true
        }
      })
    end)
end

--[[ Scenario ]]
for i, cap in utils.spairs(missingCapability) do
  runner.Title("Test case [" .. i .. "], missing capability: '" .. cap .. "'")
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIParams(cap) })
  runner.Step("Register App", common.registerAppWOPTU)

  runner.Title("Test")
  runner.Step("Ignition Off", ignitionOff)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Reregister App", reRegisterApp)

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end