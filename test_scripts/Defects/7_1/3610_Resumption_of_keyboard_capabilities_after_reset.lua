----------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3610
----------------------------------------------------------------------------------------------------
-- Description: Check SDL doesn't not resume App's keyboard properties if they have been reset
--
-- Steps:
-- 1. App is registered
-- 2. App sends 'SetGlobalProperties' with some non-default values for 'KeyboardProperties'
-- 3. App sends 'ResetGlobalProperties' for 'KEYBOARDPROPERTIES'
-- 4. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start data resumption process
--  - Not send 'KeyboardProperties' within 'UI.SetGlobalProperties' request to HMI
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashId
local sgpParams = {
  vrHelpTitle = "title",
  vrHelp = { { text = "text1", position = 1 } },
  keyboardProperties = {
    language = "EN-US",
    keyboardLayout = "AZERTY",
    keypressMode = "SINGLE_KEYPRESS",
    limitedCharacterList = { "a" },
    autoCompleteList = { "Daemon, Freedom" }
  }
}

local defaultSGPParams = {
  keyboardProperties = {
    language = "EN-US",
    keyboardLayout = "QWERTY",
    autoCompleteList = common.json.EMPTY_ARRAY
  }
}

local resumedSGPParams = {
  vrHelpTitle = sgpParams.vrHelpTitle,
  vrHelp = sgpParams.vrHelp
}

--[[ Local Functions ]]
local function reRegisterApp()
  common.getMobileSession():StartService(7)
  :Do(function()
    local appParams = utils.cloneTable(common.app.getParams())
    appParams.hashID = hashId
    local cid = common.getMobileSession():SendRPC("RegisterAppInterface", appParams)
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    :Do(function()
        local dataToHMI = utils.cloneTable(resumedSGPParams)
        common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
        :Do(function(_, data)
            common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          end)
        :ValidIf(function(_, data)
            if data.params.keyboardProperties ~= nil then
              return false, "Unexpected 'keyboardProperties' parameter received"
            end
            return true
          end)
      end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  end)
end

local function sendSetGP()
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
  local dataToHMI = utils.cloneTable(sgpParams)
  dataToHMI.appID = common.getHMIAppId()
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", sgpParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendResetGP()
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
  local params = { properties = { "KEYBOARDPROPERTIES" } }
  local dataToHMI = utils.cloneTable(defaultSGPParams)
  dataToHMI.appID = common.getHMIAppId()
  local cid = common.getMobileSession():SendRPC("ResetGlobalProperties", params)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  common.mobile.disconnect()
  common.run.wait(1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("App sends SetGP", sendSetGP)
runner.Step("App sends ResetGP", sendResetGP)
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Re-register App", reRegisterApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
