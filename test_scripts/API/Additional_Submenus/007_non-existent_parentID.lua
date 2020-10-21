---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0148-template-additional-submenus.md#backwards-compatibility
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3524
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. App sends 'AddSubMenu' request with non-existent 'parentID'
--
-- Expected:
-- SDL does:
--   - not transfer request to HMI
--   - respond to App with: false:INVALID_ID
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local parentId = 1
local child1Id = 2
local child2Id = 3
local nonExistentId = 4

--[[ Local Functions ]]
local function sendAddSubMenu_Success(pMenuId, pParentId)
  local params = {
    menuID = pMenuId,
    menuName = "SubMenupositive" .. pMenuId,
    parentID = pParentId
  }
  local hmiReqParams = {
    menuID = params.menuID,
    menuParams = {
      position = params.position,
      menuName = params.menuName,
      parentID = params.parentID
    },
    appID = common.getHMIAppId()
  }
  local cid = common.getMobileSession():SendRPC("AddSubMenu", params)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", hmiReqParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function sendAddSubMenu_Failed(pMenuId, pParentId)
  local params = {
    menuID = pMenuId,
    menuName = "SubMenupositive" .. pMenuId,
    parentID = pParentId
  }
  local cid = common.getMobileSession():SendRPC("AddSubMenu", params)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_ID" })
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.app.registerNoPTU)
runner.Step("Activate App", common.app.activate)

runner.Title("Test")
runner.Step("Add parent SubMenu", sendAddSubMenu_Success, { parentId })
runner.Step("Add child SubMenu for existent parentID", sendAddSubMenu_Success, { child1Id, parentId })
runner.Step("Add child SubMenu for non-existent parentID", sendAddSubMenu_Failed, { child2Id, nonExistentId })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
