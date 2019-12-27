---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- In case mobile application sends valid SendLocation request, SDL must:
-- 1) transfer Navigation.SendLocation to HMI
-- 2) on getting Navigation.SendLocation ("SUCCESS") response from HMI, respond with (resultCode: SUCCESS, success:true)
-- to mobile application.
--
-- Description:
-- App sends SendLocation request with fake, from another RPC parameters.
--
-- Steps:
-- mobile app requests SendLocation with fake, from another RPC parameters.
--
-- Expected:
-- SDL must:
-- 1) transfer Navigation.SendLocation to HMI without fake params
-- 2) on getting Navigation.SendLocation ("SUCCESS") response from HMI, respond with (resultCode: SUCCESS, success:true)
-- to mobile application.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local requestParamsWithFake = {
    longitudeDegrees = 1.1,
	latitudeDegrees = 1.1,
	locationName ="location Name",
	locationDescription ="location Description",
	addressLines = {
		"line1",
		"line2"
	},
	phoneNumber ="phone Number",
	locationImage =	{
		value ="icon.png",
		imageType ="DYNAMIC",
		fakeParam ="fakeParam"
	},
	fakeParam ="fakeParam",
	timeStamp = {
		millisecond = 10,
		fakeParam ="fakeParam"
	}
}

local requetsParamAnotherRequest = {
	longitudeDegrees = 1.1,
	latitudeDegrees = 1.1,
	locationName ="location Name",
	locationDescription ="location Description",
	addressLines = {
		"line1",
		"line2"
	},
	phoneNumber ="phone Number",
	locationImage =	{
		value ="icon.png",
		imageType ="DYNAMIC",
		cmdID = 10
	},
	cmdID = 10,
	timeStamp = {
		millisecond = 10,
		cmdID = 10
	}
}

local expectedRequestParams = {
	longitudeDegrees = 1.1,
	latitudeDegrees = 1.1,
	locationName ="location Name",
	locationDescription ="location Description",
	addressLines = {
		"line1",
		"line2"
	},
	phoneNumber ="phone Number",
	locationImage =	{
		value ="icon.png",
		imageType ="DYNAMIC"
	},
	timeStamp = {
		millisecond = 10
	}
}

--[[ Local Functions ]]
local function sendLocation(params, paramsHMI, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)
    paramsHMI.appID = commonSendLocation.getHMIAppId()
    local deviceID = commonSendLocation.getDeviceMAC()
    paramsHMI.locationImage.value = commonSendLocation.getPathToSDL() .. "storage/"
        .. commonSendLocation.getMobileAppId(1) .. "_" .. deviceID .. "/icon.png"

    EXPECT_HMICALL("Navigation.SendLocation", paramsHMI)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :ValidIf(function(_, data)
		local ErrorMessage
		local CheckStatus = true

		if
			data.params.fakeParam or
			data.params.locationImage.fakeParam or
			data.params.timeStamp.fakeParam then
				ErrorMessage = "SDL sends to HMI fake parameters"
				CheckStatus = false
		elseif
			data.params.cmdID or
			data.params.locationImage.cmdID or
			data.params.timeStamp.cmdID then
				ErrorMessage = "SDL sends to HMI parameters from another RPC"
				CheckStatus = false
		end

	    if CheckStatus == false then
			return false, ErrorMessage
	    else
			return true
	    end
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
--[[ Preconditions ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", commonSendLocation.putFile, { "icon.png" })

--[[ Test ]]
runner.Title("Test")
runner.Step("SendLocation_fake_parameters", sendLocation, { requestParamsWithFake, expectedRequestParams })
runner.Step("SendLocation_another_request_parameters", sendLocation,
	{ requetsParamAnotherRequest, expectedRequestParams })

--[[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
