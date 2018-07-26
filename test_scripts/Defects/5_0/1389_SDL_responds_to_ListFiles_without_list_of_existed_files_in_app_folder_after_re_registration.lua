---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1389
--
-- Precondition:
-- 1) Set proper value to smartDeviceLink.ini for property:
-- 2) AppStorageFolder = storage
-- 3) Allow PutFile RPC for FULL HMILevel in policy table.
-- Description:
-- SDL responds to ListFiles without list of existed files in app folder after re-registration
-- Steps to reproduce:
-- 1) Start SDL and HMI
-- 2) Connect mobile and create mobile session
-- 3) Register mobile App
-- 4) Activate mobile App
-- 5) Send RPC "PutFile" from mobile App
-- 6) Unregister mobile App
-- 7) Register mobile App
-- 8) Send RPC "ListFiles" from mobile App
-- Expected result:
-- SDL responds to mobile app with list of existed files in app folder after re-registration.
-- Actual result:
-- SDL responds to ListFiles without list of existed files in app folder after re-registration.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Variables ]]
local putFileParams = {
	requestParams = {
		syncFileName = "icon.png",
		fileType = "GRAPHIC_PNG"
	},
	filePath = "files/icon.png"
}

local responseParams = {
	success = true,
	resultCode = "SUCCESS"
}

local allParams = {
	requestParams = {},
	responseParams = {
		success = true,
		resultCode = "SUCCESS"
   }
}

--[[ Local Functions ]]
local function PutFile(self)
	local cid = self.mobileSession1:SendRPC("PutFile", putFileParams.requestParams, putFileParams.filePath)
	self.mobileSession1:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
end

local function ListFiles(params, self)
	local cid = self.mobileSession1:SendRPC("ListFiles", params.requestParams)
	self.mobileSession1:ExpectResponse(cid, params.responseParams )
	:ValidIf (function(_, data)
		if data.payload.filenames[1] == "icon.png" then
			return true
		else
			return false, "File is absent in ListFiles"
		end
	end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)
runner.Step("Activate App", common.activate_app)
runner.Step("Upload icon file", PutFile)
runner.Step("Unregister mobile App", common.unregisterApp)
runner.Step("Register mobile App", common.rai_n)

runner.Title("Test")
runner.Step("Mobile application sends ListFiles", ListFiles, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
