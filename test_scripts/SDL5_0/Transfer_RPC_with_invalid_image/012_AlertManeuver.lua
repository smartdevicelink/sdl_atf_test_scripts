---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests AlertManeuver with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found”) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
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
        value = "missed_icon.png",
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
        value = "missed_icon.png",
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
      Params[k].image.value = common.getPathToFileInStorage(Params[k].image.value)
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
  EXPECT_HMICALL("Navigation.AlertManeuver", pParams.responseNaviParams)
  :Do(function(_, data)
    local function alertResp()
      common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
    end
    RUN_AFTER(alertResp, 2000)
  end)
  EXPECT_HMICALL("TTS.Speak", pParams.responseTtsParams)
  :Do(function(_, data)
    common.getHMIConnection():SendNotification("TTS.Started")
    local function SpeakResp()
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      common.getHMIConnection():SendNotification("TTS.Stopped")
    end
    RUN_AFTER(SpeakResp, 1000)
  end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS", info = "Requested image(s) not found" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("AlertManeuver with invalid image", alertManeuver, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
