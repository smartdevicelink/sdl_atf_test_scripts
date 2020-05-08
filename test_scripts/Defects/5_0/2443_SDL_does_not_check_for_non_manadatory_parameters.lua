---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2443
--
-- Description:
-- SDL does not check for non-manadatory parameters
-- Steps to reproduce:
-- 1) Send OnPutFile notification with no-mandatory parameters fileSize and length. 
-- Actuchual:
-- If the mobile application has no provided appropriate parameters SDL sends fileSize: null as json value to HMI
-- Expected:
-- 1) SDL sends correct no-mandatory fileSize parameter to HMI.

---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local functions ]]
function fsize (file)
	f = io.open(file,"r")
  	local current = f:seek()
  	local size = f:seek("end")
  	f:seek("set", current)
  	f:close()
  	return size
end

local function onPutFile()
    local paramsSend = {
        syncFileName = "icon_png.png",
        fileType = "GRAPHIC_PNG",
        systemFile = true
    }
    local calcFileSize = fsize("files/icon_png.png")
    local cid = common.getMobileSession():SendRPC( "PutFile", paramsSend, "files/icon_png.png")
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnPutFile")
    :ValidIf(function(_, data)
        if data.params.fileSize == calcFileSize then
            return true
        end
        return false, "SDL can't determinate non mandatory fileSize parameter"
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", info = "File was downloaded"})       
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Upload file", onPutFile)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
