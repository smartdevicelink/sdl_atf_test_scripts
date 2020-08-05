---------------------------------------------------------------------------------------------------
-- HMI requests a missing cmdIcon be updated from mobile

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. mobile sends an addcommand with an image that does not exist

-- Steps:
-- User opens the menu, and the hmi sends UI.OnUpdateFile

-- Expected:
-- Mobile receives notification that the file should be updated
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
local missingFile = "missing_file.png"
local addCommandParams = {
    cmdID = 50,
    cmdIcon = {
        value = missingFile,
        imageType = "DYNAMIC"
    },
    menuParams = {
        position = 4,
        menuName = "Command Missing Image"
    }
}

local onUpdateFileParams = {
    fileName = missingFile
}

local hmiOnUpdateFileParams = {
    fileName = missingFile,
    appID = nil
}


--[[ Local Functions ]]
local function AddCommandNoImage()
    local mobileSession = common.getMobileSession()
    local hmi = common.getHMIConnection()
    local cid = mobileSession:SendRPC("AddCommand", addCommandParams)
    
    --hmi side: expect UI.AddCommand request 
    local hmiCommands = addCommandParams
    hmiCommands.cmdIcon.value = common.getPathToFileInStorage(missingFile)
    hmi:ExpectRequest("UI.AddCommand", hmiCommands)
    :Do(function(_,data)
        --hmi side: sending UI.AddCommand response 
        hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)	
    
    --mobile side: expect AddCommand response 
    mobileSession:ExpectResponse(cid, {  success = true, resultCode = "SUCCESS"  })
end


local function ShowMenuRequestFile()
  local mobileSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  hmiOnUpdateFileParams.appID = common.getHMIAppId()
  hmi:SendNotification("UI.OnUpdateFile", hmiOnUpdateFileParams)
  mobileSession:ExpectNotification("OnUpdateFile", onUpdateFileParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Add command with non-existing image", AddCommandNoImage)
runner.Step("Show menu and request File", ShowMenuRequestFile)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
