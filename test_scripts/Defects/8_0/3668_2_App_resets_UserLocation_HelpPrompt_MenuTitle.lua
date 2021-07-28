----------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3668
----------------------------------------------------------------------------------------------------
-- Description: Check App is able to reset previously defined 'UserLocation' to default values
--
-- Steps:
-- 1. App is registered
-- 2. App sends 'SetGlobalProperties' for multiple properties
-- 3. App sends 'ResetGlobalProperties' for multiple properties
-- SDL does:
--  - Send default values for 'USER_LOCATION' to HMI within 'RC.SetGlobalProperties' request
--  - By receiving successful response from HMI transfer it to App
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
local function sendSetGlobalProperties(pGrid)
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local params = {
    userLocation = { grid = pGrid },
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

local function sendResetGlobalProperties(pGrid)
  local mobileSession = common.mobile.getSession()
  local hmi = common.hmi.getConnection()
  local params = { properties = { "USER_LOCATION", "HELPPROMPT", "MENUNAME" } }
  local function getRCExp()
    return {
      userLocation = { grid = pGrid },
      appID = common.app.getHMIId()
    }
  end
  local cid = mobileSession:SendRPC("ResetGlobalProperties", params)
  hmi:ExpectRequest("RC.SetGlobalProperties", getRCExp())
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  local function getUIExp()
    return {
      menuTitle = "",
      appID = common.app.getHMIId()
    }
  end
  hmi:ExpectRequest("UI.SetGlobalProperties", getUIExp())
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  local function getTTSExp()
    local helpPrompt = { }
    local ttsDelimiter = common.sdl.getSDLIniParameter("TTSDelimiter")
    local helpPromptString = common.sdl.getSDLIniParameter("HelpPromt")
    local helpPromptList = utils.splitString(helpPromptString, ttsDelimiter)
    for key,value in pairs(helpPromptList) do
      helpPrompt[key] = {
        type = "TEXT",
        text = value .. ttsDelimiter
      }
    end
    return {
      helpPrompt = helpPrompt,
      appID = common.app.getHMIId()
    }
  end
  hmi:ExpectRequest("TTS.SetGlobalProperties", getTTSExp() )
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("Send SetGlobalProperties with multiple properties", sendSetGlobalProperties, { grids.FRONT_PASSENGER })
runner.Step("Send ResetGlobalProperties with multiple properties", sendResetGlobalProperties, { grids.DRIVER })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
