---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0085-submenu-icon.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Mobile application sends AddSubMenu request to SDL without menuIcon parameter.
-- SDL does:
-- 1) Forward  UI.AddSubMenu request params to HMI.
-- 2) Respond with (resultCode: SUCCESS, success:true) to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SubMenuIcon/commonSubMenuIcon')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]

local function addSubMenu()
	local params = {
		menuID = 1000,
		position = 500,
		menuName ="SubMenupositive"
	}

	local corId = common.getMobileSession():SendRPC("AddSubMenu", params)
	common.getHMIConnection():ExpectRequest("UI.AddSubMenu", params.requestUiParams)
	:Do(function(_, data)
		common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_, data)
		if data.params.menuIcon then
			return false, " SDL sends menuIcon in request to HMI in case parameter is absent in request"
		end
		return true
	end)

  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Activate Application", common.activateApp)

runner.Title("Test")
runner.Step("AddSubMenu request without menuIcon", addSubMenu)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
