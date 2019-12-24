---------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1393
-- Description: This is a script to verify that SDL core responds to ListFiles from enumerating through
-- the file system (not from cash)
-- Precondition:
-- 1) Core, HMI started.
-- 2) Application is registered
-- 3) Upload the icon.png file
-- 4) App sends the ListFiles request to the SDL and receives a response with the icon.png file from the SDL
-- 5) App sends the DeleteFile request for the icon.png file to the SDL
-- Step:
-- 1) App sends the ListFiles request to the SDL
-- SDL must:
-- transfer a response with an empty list to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "icon.png",
  fileType = "GRAPHIC_PNG",
  persistentFile = false,
  systemFile = false
}

--[[ Local Functions ]]
local function putFile()
  local cid = common.getMobileSession():SendRPC("PutFile", requestParams ,"files/icon.png" )
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function listFiles(pResult)
  local cid = common.getMobileSession():SendRPC("ListFiles", {} )
  if pResult then
    common.getMobileSession():ExpectResponse(cid,
      { success = true, resultCode = "SUCCESS",filenames = { "icon.png" } })
  else
    common.getMobileSession():ExpectResponse(cid,
      { success = true, resultCode = "SUCCESS",filenames = nil })
  end
end

local function deleteFile()
  local cid = common.getMobileSession():SendRPC("DeleteFile", { syncFileName = requestParams.syncFileName })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload file", putFile)

runner.Title("Test")
runner.Step("ListFiles with the icon.png file in the list", listFiles, { true })
runner.Step("Delete the icon.png file via DeleteFile RPC", deleteFile)
runner.Step("ListFiles with an empty list", listFiles, { false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
