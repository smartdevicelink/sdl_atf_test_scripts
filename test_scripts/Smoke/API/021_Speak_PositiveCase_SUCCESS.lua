---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: Speak
-- Item: Happy path
--
-- Requirement summary:
-- [Speak] SUCCESS on TTS.Speak
--
-- Description:
-- Mobile application sends Speak request with valid parameters to SDL
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends Speak request with valid parameters to SDL
--
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if TTS interface is available on HMI
-- SDL checks if Speak is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the TTS part of request with allowed parameters to HMI
-- SDL receives TTS part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Functions ]]
local function getRequestParams()
	return {
		ttsChunks = {
			{
				text ="a",
				type ="TEXT"
			}
		}
	}
end

local function speakSuccess(self)
	print("Waiting 20s ...")
	local cid = self.mobileSession1:SendRPC("Speak", getRequestParams())
	EXPECT_HMICALL("TTS.Speak", getRequestParams())
	:Do(function(_, data)
			self.hmiConnection:SendNotification("TTS.Started")
			local function sendSpeakResponse()
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
				self.hmiConnection:SendNotification("TTS.Stopped")
			end
			local function sendOnResetTimeout()
				self.hmiConnection:SendNotification("TTS.OnResetTimeout",
					{ appID = commonSmoke.getHMIAppId(), methodName = "TTS.Speak" })
			end
			RUN_AFTER(sendOnResetTimeout, 9000)
			RUN_AFTER(sendSpeakResponse, 18000)
		end)

		self.mobileSession1:ExpectNotification("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
			{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
		:Times(2)
		:Timeout(20000)

	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	:Timeout(20000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Speak Positive Case", speakSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
