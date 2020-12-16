---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/3511
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. There is no HMI Capabilities cache file
-- 2. SDL first start
-- 3. HMI provides bitsPerSample="16_BIT" in pcmStreamCapabilities and audioPassThruCapabilities structs
-- 4. App registers
-- 5. SDL provides all the capabilities received from HMI
-- 6. SDL stores all HMI capabilities into HMI Capabilities cache file
-- 7. Ignition Off/On cycle
-- 8. App re-registers
--
-- Expected:
-- SDL uses the values from HMI Capabilities cache file and provides this data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local hmi_values = require('user_modules/hmi_values')
local SDL = require("SDL")
local color = require("user_modules/consts").color
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local expVal = "16_BIT"

local testCases = {
  [1] = {
    updUICapsFunc = function(pUICaps)
      pUICaps.pcmStreamCapabilities.bitsPerSample = expVal
      pUICaps.audioPassThruCapabilitiesList[1].bitsPerSample = expVal
    end
  },
  [2] = {
    updUICapsFunc = function(pUICaps)
      pUICaps.pcmStreamCapabilities.bitsPerSample = expVal
      pUICaps.audioPassThruCapabilitiesList = nil
      pUICaps.audioPassThruCapabilities.bitsPerSample = expVal
    end
  }
}

--[[ Local Functions ]]
local function getUpdatedHMICaps(pTC)
  local hmiParams = utils.cloneTable(hmi_values.getDefaultHMITable())
  testCases[pTC].updUICapsFunc(hmiParams.UI.GetCapabilities.params)
  return hmiParams
end

local function ignitionOff()
  local isOnSDLCloseSent = false
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  common.run.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then common.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, common.mobile.getAppsCount() do
      common.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

local function registerApp()
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
      local cid = session:SendRPC("RegisterAppInterface", common.app.getParams())
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      session:ExpectResponse(cid, {
        success = true,
        resultCode = "SUCCESS",
        pcmStreamCapabilities = { bitsPerSample = expVal },
        audioPassThruCapabilities = { { bitsPerSample = expVal } }
      })
    end)
end

--[[ Scenario ]]
for tc in pairs(testCases) do
  runner.Title("Test Case [" .. tc .. "]")
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getUpdatedHMICaps(tc) })

  runner.Title("Test")
  runner.Step("Register App", registerApp)
  runner.Step("Ignition Off", ignitionOff)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Register App", registerApp)

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end
