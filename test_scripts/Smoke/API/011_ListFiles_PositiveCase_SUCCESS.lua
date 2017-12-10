---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ListFiles
-- Item: Happy path
--
-- Requirement summary:
-- [ListFiles]: SUCCESS result code
--
-- Description:
-- Mobile application sends ListFiles request with valid parameters to SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests ListFiles with valid parameters to SDL

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if ListFiles is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL provides the list of filenames which are stored in the app`s folder
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Local Variables ]]
local testFileNamesList = {
	string.rep("a", 251)  .. ".png",
	" SpaceBefore",
	"icon.png"
}

local putFileParams = {
	requestParams = {
	    syncFileName = "",
	    fileType = "GRAPHIC_PNG",
	    persistentFile = false,
	    systemFile = false
	},
	filePath = "files/icon.png"
}

local requestParams = {}

local responseParams = {
	success = true,
    resultCode = "SUCCESS",
	spaceAvailable = 103878520
}

local allParams = {
	requestParams = requestParams,
	responseParams = responseParams
}

--[[ Local Functions ]]
local function putFile(fileName, self)
	putFileParams.requestParams.syncFileName = fileName
	commonSmoke.putFile(putFileParams, 1, self)
end

local function listFiles(params, self)
	local cid = self.mobileSession1:SendRPC("ListFiles", params.requestParams)

	self.mobileSession1:ExpectResponse(cid, params.responseParams)
  	:ValidIf(function(_, data)
  		if not commonFunctions:is_table_equal(data.payload.filenames, testFileNamesList) then
        	return false, "\nExpected files:\n" .. commonFunctions:convertTableToString(testFileNamesList, 1)
          		.. "\nActual files:\n" .. commonFunctions:convertTableToString(data.payload.filenames, 1)
      	end
    	return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)
for i, fileName in ipairs(testFileNamesList) do
	runner.Step("Upload test file #" .. i, putFile, {fileName})
end

runner.Title("Test")
runner.Step("ListFiles Positive Case", listFiles, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
