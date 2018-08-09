---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2379
--
-- Precondition:
-- SDL must send log error and ignore invalid RPC in case SDL cuts off fake parameters and RPC becomes invalid
-- Description:
-- Steps to reproduce:
-- 1) SDL cuts off fake parameters from response (request) that SDL should use internally and this response (request) is invalid by any reason
-- Expected:
-- 1) Log the corresponding error
-- 2) Ignore this response (request)
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local variables ]]
local requestParams = {
  menuID = 10,
  position = 5,
  menuName ="SubMenupositive",
  fakeParam = 0001
}

local responseUiParams = {
  menuID = requestParams.menuID,
  menuParams = {
    position = requestParams.position,
    menuName = requestParams.menuName
  }
}

--[[ Local Functions ]]
local function addSubMenuValid()
  local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", responseUiParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_, data)
    if data.params.fakeParam then
      return false, "SDL sent UI.AddSubMenu wit fake parameter to HMI"
    end
    return true
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function addSubMenuInvalidData()
  requestParams.position = "5"
  local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
  common.getHMIConnection():ExpectRequest("AddSubMenu")
  :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Add Submenu", addSubMenuValid)
runner.Step("Add Submenu with Invalid Data", addSubMenuInvalidData)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
