---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3667
---------------------------------------------------------------------------------------------------
-- Description: Check SDL sends RC.SetGlobalProperties with default user location in case of a failed resumption
--
-- Preconditions:
-- 1. Clean environment
-- 2. SDL, HMI, Mobile session started
-- 3. Registered app
-- 4. Activated app
--
-- Steps:
-- 1. App sends SetGlobalProperties with parameters "helpPrompt", "userLocation" and "menuTitle"
-- SDL does:
--  - Send UI.SetGlobalProperties to the HMI with parameter "menuTitle"
--  - Send TTS.SetGlobalProperties to the HMI with parameter "helpPrompt"
--  - Send RC.SetGlobalProperties to the HMI with parameter "userLocation"
-- 2. App unexpectedly disconnects and reconnects
-- SDL does:
--  - Start resumption process
--  - Send UI.SetGlobalProperties to the HMI with parameter "menuTitle" and correct value
--  - Send TTS.SetGlobalProperties to the HMI with parameter "helpPrompt" and correct value
--  - Send RC.SetGlobalProperties to the HMI with parameter "userLocation" and correct value
-- 3. HMI responds to UI.SetGlobalProperties with "GENERIC_ERROR"
-- SDL does:
--  - Send TTS.SetGlobalProperties to the HMI with parameter "helpPrompt" and default value
--  - Send RC.SetGlobalProperties to the HMI with parameter "userLocation" and default value
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local helpPrompt = {
  {
    text = "Some text",
    type = "TEXT"
  }
}

local defaultHelpPrompt = {
  {
    text = "Please speak one of the following commands,",
    type = "TEXT"
  },
  {
    text = "Please say a command,",
    type = "TEXT"
  }
}

local userLocation = {
  grid = {
    col = 2,
    colspan = 1,
    level = 2,
    levelspan = 1,
    row = 2,
    rowspan =1
  }
}

local defaultUserLocation = {
  grid = {
    col = 0,
    colspan = 1,
    level = 0,
    levelspan = 1,
    row = 0,
    rowspan =1
  }
}

local menuTitle = "Menu Title"

-- [[ Local Functions ]]
local function setGlobalProperties(pAppId)
  if not pAppId then pAppId = 1 end
  local hmiAppId = common.getHMIAppId(pAppId)

  local cid = common.getMobileSession(pAppId):SendRPC("SetGlobalProperties", {
    helpPrompt = helpPrompt,
    userLocation = userLocation,
    menuTitle = menuTitle
  })

  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", {menuTitle = menuTitle, appID = hmiAppId})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", {helpPrompt = helpPrompt, appID = hmiAppId})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getHMIConnection():ExpectRequest("RC.SetGlobalProperties", {userLocation = userLocation, appID = hmiAppId})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession(pAppId):ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
        common.hashId[pAppId] = data.payload.hashID
  end)
end

local function checkResumptionData(pAppId)
  if not pAppId then pAppId = 1 end
  local hmiAppId = common.getHMIAppId(pAppId)

  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", {menuTitle = menuTitle, appID = hmiAppId})
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, 
          "GENERIC_ERROR", {message = "Erroneous response is assigned by settings"})
    end)

    common.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", 
      {helpPrompt = helpPrompt, appID = hmiAppId},        -- Resumption request
      {helpPrompt = defaultHelpPrompt, appID = hmiAppId}  -- Reset global property request

    )
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :Times(2)

    common.getHMIConnection():ExpectRequest("RC.SetGlobalProperties", 
      {userLocation = userLocation, appID = common.getHMIAppId()},        -- Resumption request
      {userLocation = defaultUserLocation, appID = common.getHMIAppId()}  -- Reset global property request
    )
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerAppWOPTU)
runner.Step("Activate app", common.activateApp)

runner.Title("Test")
runner.Step("SetGlobalProperties SUCCESS", setGlobalProperties)
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterAppResumeFailed,
  { 1, checkResumptionData, common.resumptionFullHMILevel })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
