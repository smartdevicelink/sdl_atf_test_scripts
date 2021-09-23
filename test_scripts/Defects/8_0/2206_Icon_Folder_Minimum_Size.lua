---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2206
---------------------------------------------------------------------------------------------------
-- Description: 'AppIconsFolderMaxSize' in smartDeviceLink.ini
-- cannot be configured to be less than 100MB
--
-- Steps:
-- 1. Update smartDeviceLink.ini file to:
--  - set a dedicated folder for AppIconsFolder e.g. "icons"
--  - set 10240 for AppIconsFolderMaxSize i.e. 10KB
-- 2. Start SDL Core and Connect App
-- 3. App sets a new app icon that is less than 100MB
--  - by sending PutFile of an image
--  - and then sending SetAppIcon
--
-- SDL does:
--  - not save the image file that is larger than AppIconsFolderMaxSize to icons folder
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
    requestParams = {
        syncFileName = "dummy",
        fileType = "GRAPHIC_PNG",
        persistentFile = false,
        systemFile = false
    },
    filePath = "files/icon.png"
}

--[[ Local Functions ]]
local function setAppIcon()
    local mobSession = common.getMobileSession(1)

    local cid = mobSession:SendRPC("PutFile", putFileParams.requestParams, putFileParams.filePath)
    mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

    local cid = mobSession:SendRPC("SetAppIcon", { syncFileName = "dummy" })
    EXPECT_HMICALL("UI.SetAppIcon", {})
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function doesIconFileExist()
    local iconPath = commonPreconditions:GetPathToSDL() .. "empty_icons/" .. common.app.getPolicyAppId(1)
    local exit = os.execute("ls " .. iconPath)
    if exit ~= nil and exit ~= false then
        common.run.fail("File still exists after starting core")
    end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set Folder for Icon Storage", common.setSDLIniParameter, { "AppIconsFolder", "empty_icons" })
runner.Step("Restrict AppIconsFolderMaxSize", common.setSDLIniParameter, { "AppIconsFolderMaxSize", "10240" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App send SetAppIcon", setAppIcon)
runner.Step("Check that file was deleted", doesIconFileExist)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
