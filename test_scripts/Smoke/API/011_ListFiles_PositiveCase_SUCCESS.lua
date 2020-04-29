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
local common = require('test_scripts/Smoke/commonSmoke')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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
	resultCode = "SUCCESS"
}

local allParams = {
  requestParams = requestParams,
  responseParams = responseParams
}

--[[ Local Functions ]]
local function putFile(pFileName)
  putFileParams.requestParams.syncFileName = pFileName
  common.putFile(putFileParams, 1)
end

local function listFiles(params)
  local cid = common.getMobileSession():SendRPC("ListFiles", params.requestParams)

  common.getMobileSession():ExpectResponse(cid, params.responseParams)
  :ValidIf(function(_, data)
      if not commonFunctions:is_table_equal(data.payload.filenames, testFileNamesList) then
        return false, "\nExpected files:\n" .. commonFunctions:convertTableToString(testFileNamesList, 1)
          .. "\nActual files:\n" .. commonFunctions:convertTableToString(data.payload.filenames, 1)
      end
      return true
    end)
  :ValidIf(function(_, data)
      if not data.payload.spaceAvailable or data.payload.spaceAvailable == 0 then
        return false, "'spaceAvailable' is not provided or zero"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
for i, fileName in ipairs(testFileNamesList) do
  runner.Step("Upload test file #" .. i, putFile, { fileName })
end

runner.Title("Test")
runner.Step("ListFiles Positive Case", listFiles, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
