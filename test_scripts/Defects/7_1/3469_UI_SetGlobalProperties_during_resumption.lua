---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3469
---------------------------------------------------------------------------------------------------
-- Description: Check SDL sends UI.SetGlobalProperties during resumption if app defines global properties
-- with any UI parameter
--
-- Steps:
-- 1. App is registered
-- 2. App sends SetGlobalProperties with some parameter related to UI interface
-- 3. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start resumption process
--  - Send UI.SetGlobalProperties with defined parameter and correct value
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [01] = {
    vrHelpTitle = "title",
    vrHelp = {
      { text = "text1", position = 1 }
    }
  },
  [02] = {
    menuTitle = "menuTitle_1"
  },
  [03] = {
    menuIcon = {
      value = "icon.png",
      imageType = "STATIC"
    }
  },
  [04] = {
    keyboardProperties = {
      language = "EN-US",
      keyboardLayout = "AZERTY",
      keypressMode = "SINGLE_KEYPRESS",
      limitedCharacterList = { "a" },
      autoCompleteList = { "Daemon, Freedom" }
    }
  }
}

local hashId

--[[ Local Functions ]]
local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(common.mobile.getAppsCount())
  common.mobile.disconnect()
  utils.wait(1000)
end

local function sendSetGlobalProperties(pParams)
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", pParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
end

local function registerApp()
  common.app.getParams().hashID = nil
  common.app.registerNoPTU()
end

local function reRegisterApp(pParams)
  common.app.getParams().hashID = hashId
  common.app.registerNoPTU()
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function putFile()
  local params = {
    requestParams = {
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false
    },
    filePath = "files/action.png"
  }
  local cid = common.getMobileSession():SendRPC("PutFile", params.requestParams, params.filePath)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
for n, tc in utils.spairs(testCases) do
  runner.Title("TC[" .. string.format("%02d", n) .. "]: " .. next(tc))
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Register App", registerApp)
  runner.Step("Upload icon file", putFile)
  runner.Step("Set RC Global Properties", sendSetGlobalProperties, { tc })

  runner.Title("Test")
  runner.Step("Unexpected disconnect", unexpectedDisconnect)
  runner.Step("Connect mobile", common.mobile.connect)
  runner.Step("Re-register App", reRegisterApp, { tc })

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end
