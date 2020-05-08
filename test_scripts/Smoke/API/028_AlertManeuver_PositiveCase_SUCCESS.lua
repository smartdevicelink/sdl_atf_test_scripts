---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: AlertManeuver
-- Item: Happy path
--
-- Requirement summary:
-- [AlertManeuver] SUCCESS on Navigation.AlertManeuver
--
-- Description:
-- Mobile application sends AlertManeuver request with valid parameters to SDL
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends AlertManeuver request with valid parameters to SDL
--
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if Navigation interface is available on HMI
-- SDL checks if TTS interface is available on HMI
-- SDL checks if AlertManeuver is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the Navigation part of request with allowed parameters to HMI
-- SDL transfers the TTS part of request with allowed parameters to HMI
-- SDL receives Navigation part of response from HMI with "SUCCESS" result code
-- SDL receives TTS part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local requestParams = {
  ttsChunks = {
    {
      text = "FirstAlert",
      type = "TEXT",
    },
    {
      text = "SecondAlert",
      type = "TEXT",
    },
  },
  softButtons = {
    {
      type = "BOTH",
      text = "Close",
      image = {
        value = "icon.png",
        imageType = "DYNAMIC",
      },
      isHighlighted = true,
      softButtonID = 821,
      systemAction = "DEFAULT_ACTION",
    },
    {
      type = "BOTH",
      text = "AnotherClose",
      image = {
        value = "icon.png",
        imageType = "DYNAMIC",
      },
      isHighlighted = false,
      softButtonID = 822,
      systemAction = "DEFAULT_ACTION",
    },
  }
}

local function naviParamsSet(tbl)
  local Params = common.cloneTable(tbl)
  for k, _ in pairs(Params) do
    if Params[k].image then
      Params[k].image.value = common.getPathToFileInAppStorage(Params[k].image.value)
    end
  end
  return Params
end

local responseNaviParams = {
  softButtons = naviParamsSet(requestParams.softButtons)
}

local responseTtsParams = {
  ttsChunks = requestParams.ttsChunks
}

local allParams = {
  requestParams = requestParams,
  responseNaviParams = responseNaviParams,
  responseTtsParams = responseTtsParams
}

--[[ Local Functions ]]
local function alertManeuver(pParams)
  local cid = common.getMobileSession():SendRPC("AlertManeuver", pParams.requestParams)
  common.getHMIConnection():ExpectRequest("Navigation.AlertManeuver", pParams.responseNaviParams)
  :Do(function(_, data)
      local function alertResp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      common.runAfter(alertResp, 2000)
    end)
  common.getHMIConnection():ExpectRequest("TTS.Speak", pParams.responseTtsParams)
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("TTS.Started")
      local function SpeakResp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.runAfter(SpeakResp, 1000)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { putFileParams })

runner.Title("Test")
runner.Step("AlertManeuver Positive Case", alertManeuver, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
