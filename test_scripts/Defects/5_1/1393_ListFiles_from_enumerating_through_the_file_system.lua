---------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1393
--
-- Description: Check that SDL responds to ListFiles request from enumerating through the file system
--
-- Precondition:
-- 1) Core and HMI are started.
-- 2) Application is registered
-- 3) Upload the icon.png file
-- 4) App sends the ListFiles request to the SDL and receives a response with the icon.png file from the SDL
-- 5) App sends the DeleteFile request for the icon.png file to the SDL
-- Step:
-- 1) App sends the ListFiles request to the SDL
-- SDL does:
-- - send ListFiles response with an empty list to the App
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
      { success = true, resultCode = "SUCCESS", filenames = { "icon.png" } })
  else
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf (function(_,data)
      if data.payload.filenames then
        return false, "ListFiles response contains unexpected parameter 'filenames' \n"
      end
      return true
    end)
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
runner.Step("Upload icon.png file", putFile)

runner.Title("Test")
runner.Step("ListFiles with the icon.png file", listFiles, { true })
runner.Step("DeleteFile with the icon.png file", deleteFile)
runner.Step("ListFiles with an empty list", listFiles, { false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
