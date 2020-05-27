---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/885
-- Description:
-- For some RPCs, Core does not unsubscribe from softbuttons after receiving a response
-- Precondition:
-- SDL and HMI are started
-- In case:
-- 1) App is registered and activated
-- 2) App sends "UpdateTurnList" request
-- Expected result:
-- 1) For all of the popup-based RPCs which contain softButtons, Core is supposed to stop processing softButton events once a response is received for the RPC.
-- Currently the only one that does this is ScrollableMessage, for all of the others Core stays subscribed to their softButtons after receiving a response.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
    local VDgroup = {
        rpcs = {
            UpdateTurnList = {
                hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
            }
        }
    }
    tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4",
    "NewTestCaseGroup"}
end

local function UpdateTurnList()
    local params = {
        softButtons = {
            { type = "TEXT", softButtonID = 4, text = "text" }
        }
    }
    local responseDelay = 3000
    local cid = common.getMobileSession():SendRPC("UpdateTurnList", params )
    EXPECT_HMICALL("Navigation.UpdateTurnList",{
        appID = common.getHMIAppId(),
        softButtons = {
            { type = "TEXT", softButtonID = 4, text = "text" }
        }
    })
    :Do(function(_, data)
        local function updateTurnListResponse()
            common.getHMIConnection():SendResponse(data.id, "Navigation.UpdateTurnList", "SUCCESS", { })
        end
        RUN_AFTER(updateTurnListResponse, responseDelay)
    end)
	:Do(function()
		local function ButtonEventPress()
            common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
			{ name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 4, appID = common.getHMIAppId()
			})
            common.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
			{ name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 4, appID = common.getHMIAppId()
			})
            common.getHMIConnection():SendNotification("Buttons.OnButtonPress",
			{ name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 4, appID = common.getHMIAppId()
			})
		end

		RUN_AFTER(ButtonEventPress, 1000)
	end)
    common.getMobileSession():ExpectNotification("OnButtonEvent",
    {buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 4 },
    {buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 4 })
    :Times(2)
    common.getMobileSession():ExpectNotification("OnButtonPress",
    {buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 4 })

    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Update ptu", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("ShowConstantTBT with soft buttons", UpdateTurnList)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
