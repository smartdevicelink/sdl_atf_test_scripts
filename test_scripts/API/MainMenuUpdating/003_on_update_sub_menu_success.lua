---------------------------------------------------------------------------------------------------
-- HMI requests a subemenu is populated

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. mobile sends an addSubMenu request with no other contents

-- Steps:
-- User opens the menu, and the hmi sends UI.OnUpdateSubMenu

-- Expected:
-- Mobile receives notification that the submenu should be updated
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local addSubMenu = {
    menuID = 50,
    menuName = "Sub Menu"
}

local addSubMenuHMI = {
    menuID = 50,
    menuParams = {
        menuName = "Sub Menu"
    }
}

local onUpdateSubMenu = {
    menuID = 50,
    updateSubCells = true
}


--[[ Local Functions ]]
local function AddSubMenuNoCommands()
    local mobileSession = common.getMobileSession()
    local hmi = common.getHMIConnection()
    local cid = mobileSession:SendRPC("AddSubMenu", addSubMenu)
    
    --hmi side: expect UI.AddCommand request 
    hmi:ExpectRequest("UI.AddSubMenu", addSubMenuHMI)
    :Do(function(_,data)
        --hmi side: sending UI.AddCommand response 
        hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)	
    
    --mobile side: expect AddCommand response 
    mobileSession:ExpectResponse(cid, {  success = true, resultCode = "SUCCESS"  })
end


local function ShowMenuRequestCommands()
  local mobileSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  onUpdateSubMenu.appID = common.getHMIAppId()
  hmi:SendNotification("UI.OnUpdateSubMenu", onUpdateSubMenu)
  onUpdateSubMenu.appID = nil
  mobileSession:ExpectNotification("OnUpdateSubMenu", onUpdateSubMenu)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Add command with non-existing image", AddSubMenuNoCommands)
runner.Step("Show menu and request submenu commands", ShowMenuRequestCommands)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
