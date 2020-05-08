---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: DeleteFile
-- Item: Happy path
--
-- Requirement summary:
-- [DeleteFile] SUCCESS on successful file removal from an application folder
--
-- Description:
-- Mobile application sends valid DeleteFile request with syncFileName

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level
-- d. File with syncFileName is exists

-- Steps:
-- appID requests DeleteFile request with syncFileName

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if DeleteFile is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL removes an appropriate file with "syncFileName" in AppStorageFolder
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
-- SDL notifies HMI with OnFileRemoved(syncFileName) notification about the file has been removed
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
  syncFileName = putFileParams.requestParams.syncFileName
}

local responseBcParams = {
  fileName = putFileParams.requestParams.syncFileName,
  fileType = putFileParams.requestParams.fileType
}

local createAllParams = {
  requestParams = requestParams,
  responseBcParams = responseBcParams
}

--[[ Local Functions ]]
local function deleteFile(pParams)
  local cid = common.getMobileSession():SendRPC("DeleteFile", pParams.requestParams)

  pParams.responseBcParams.appID = common.getHMIAppId()
  pParams.responseBcParams.fileName = common.getPathToFileInAppStorage(pParams.responseBcParams.fileName)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnFileRemoved", pParams.responseBcParams)

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
runner.Step("DeleteFile Positive Case", deleteFile, { createAllParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
