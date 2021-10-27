----------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3668
----------------------------------------------------------------------------------------------------
-- Description: Check SDL transfer erroneous response to the App in case HMI responds
-- with unsuccessful result code to at least one 'SetGlobalProperties' request
--
-- Steps:
-- 1. App is registered
-- 2. App sends 'SetGlobalProperties' for multiple properties
-- 3. App sends 'ResetGlobalProperties' for multiple properties
-- SDL does:
--  - Send a few SetGlobalProperties requests to  HMI
-- 4. HMI responds with unsuccessful result code to at least one request
-- SDL does:
--  - Transfer erroneous response to the App
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local grids = {
  DRIVER = { col = 0, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 },
  FRONT_PASSENGER = { col = 2, colspan = 1, row = 0, rowspan = 1, level = 0, levelspan = 1 }
}

--[[ Local Functions ]]
local function sendSetGlobalProperties()
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local params = {
    userLocation = { grid = grids.FRONT_PASSENGER },
    menuTitle = "Menu Title",
    helpPrompt = { { text = "Help Prompt", type = "TEXT" } }
  }
  local cid = mobileSession:SendRPC("SetGlobalProperties", params)
  hmi:ExpectRequest("RC.SetGlobalProperties", {
    userLocation = params.userLocation,
    appID = common.app.getHMIId()
  })
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  hmi:ExpectRequest("UI.SetGlobalProperties", {
    menuTitle = params.menuTitle,
    appID = common.app.getHMIId()
  })
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  hmi:ExpectRequest("TTS.SetGlobalProperties", {
    helpPrompt = params.helpPrompt,
    appID = common.app.getHMIId()
  })
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendResetGlobalProperties(pIfaceError)
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local params = { properties = { "USER_LOCATION", "HELPPROMPT", "MENUNAME" } }
  local cid = mobileSession:SendRPC("ResetGlobalProperties", params)
  local function sendResponse(data)
    local iface = utils.splitString(data.method, '.')[1]
    if iface == pIfaceError then
      hmi:SendError(data.id, data.method, "REJECTED", "Error message")
    else
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end
  end
  hmi:ExpectRequest("RC.SetGlobalProperties")
  :Do(function(_, data)
      sendResponse(data)
    end)
  hmi:ExpectRequest("UI.SetGlobalProperties")
  :Do(function(_, data)
      sendResponse(data)
    end)
  hmi:ExpectRequest("TTS.SetGlobalProperties")
  :Do(function(_, data)
      sendResponse(data)
    end)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
for _, iface in pairs({"UI", "TTS", "RC"}) do
  runner.Title("Erroneous response from HMI for interface " .. iface)
  runner.Step("Send SetGlobalProperties with multiple properties", sendSetGlobalProperties)
  runner.Step("Send ResetGlobalProperties with erroneous response from HMI", sendResetGlobalProperties, { iface })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
