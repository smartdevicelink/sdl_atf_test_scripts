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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

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
  local Params = commonFunctions:cloneTable(tbl)
  for k, _ in pairs(Params) do
    if Params[k].image then
      Params[k].image.value = commonSmoke.getPathToFileInStorage(Params[k].image.value)
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
local function PTUpdateFunc(tbl)
  local AlertMgroup = {
    rpcs = {
      AlertManeuver = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
      }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup = AlertMgroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
  { "Base-4", "NewTestCaseGroup" }
end

local function alertManeuver(pParams, self)
  local cid = self.mobileSession1:SendRPC("AlertManeuver", pParams.requestParams)
  EXPECT_HMICALL("Navigation.AlertManeuver", pParams.responseNaviParams)
  :Do(function(_, data)
    local function alertResp()
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end
    RUN_AFTER(alertResp, 2000)
  end)
  EXPECT_HMICALL("TTS.Speak", pParams.responseTtsParams)
  :Do(function(_, data)
    self.hmiConnection:SendNotification("TTS.Started")
    local function SpeakResp()
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      self.hmiConnection:SendNotification("TTS.Stopped")
    end
    RUN_AFTER(SpeakResp, 1000)
  end)
  self.mobileSession1:ExpectNotification("OnHMIStatus")
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU, { 1, PTUpdateFunc })
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, { putFileParams })

runner.Title("Test")
runner.Step("AlertManeuver Positive Case", alertManeuver, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
