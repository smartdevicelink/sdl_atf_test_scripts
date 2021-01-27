---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1597
--
-- Description:
-- HMI responds with UNSUPPORTED_RESOURCE to Speak component of PerformAudioPassThru
--
-- Preconditions:
-- 1) Clean environment
-- 2) SDL, HMI, Mobile session started
-- 3) Registered app
-- 4) Activated app
--
-- Steps: 
-- 1) Send PerformAudioPassThru mobile RPC from app with ttsChunks, HMI responds with UNSUPPORTED_RESOURCE to 
--    Speak request
--
-- Expected:
-- 1) App receives PerformAudioPassThru response with info from Speak response, WARNINGS result code, 
--    and success=true
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendOnSystemContext(ctx, pWindowId, pAppId)
  if not pWindowId then pWindowId = 0 end
  if not pAppId then pAppId = 1 end
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
  {
    appID = common.getHMIAppId(pAppId),
    systemContext = ctx,
    windowID = pWindowId
  })
end

local function sendPerformAudioPassThru()
  local cid = common.getMobileSession():SendRPC("PerformAudioPassThru", { 
    audioPassThruDisplayText1 = "Message",
    samplingRate = "8KHZ",
    maxDuration = 10000,
    bitsPerSample = "8_BIT",
    audioType = "PCM",
    initialPrompt = { 
      { type = "LHPLUS_PHONEMES", text = "phoneme" }
    }
  })
  common.getHMIConnection():ExpectRequest("UI.PerformAudioPassThru")
  :Do(function(_, data)
      sendOnSystemContext("HMI_OBSCURED")
      common.run.runAfter(function()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        sendOnSystemContext("MAIN")
      end, 2000)
    end)
  common.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function(_, data)
      common.run.runAfter(function()
        common.getHMIConnection():SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Error message from HMI")
      end, 1000)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS", info = "Error message from HMI" })
end

--[[ Scenario ]]
runner.Title("Precondition")
runner.Step("Clean environment and Back-up/update PPT", common.preconditions)
runner.Step("Start SDL, HMI", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("PerformAudioPassThru", sendPerformAudioPassThru)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
