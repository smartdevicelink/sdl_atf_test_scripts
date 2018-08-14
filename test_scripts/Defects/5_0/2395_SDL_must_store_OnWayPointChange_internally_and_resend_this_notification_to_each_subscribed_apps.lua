---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2395
--
-- Description:
-- SDL must store OnWayPointChange internally and re-send this notification to each subscribed apps
-- Steps to reproduce:
-- 1) App_1 and app_2 successfully subscribes on wayPonts-related data
--    and SDL stores OnWayPointChange (<wayPoints_1>) notification received from HMI
--    and HMI sends OnWayPointChange (<wayPoints_2>) notification to SDL
-- 2) App_1 successfully subscribes on wayPonts-related data
--    and HMI sends OnWayPointChange () notification to SDL
-- Expected:
-- 1) SDL must store OnWayPointChange internally and re-send this notification to each subscribed apps
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local notifParams = {
wayPoints =
    {
        {
            coordinate = {
            latitudeDegrees = -90,
            longitudeDegrees = -180
            },
            locationName = "Ho Chi Minh",
            addressLines = {"182 Le Dai Hanh"},
            locationDescription = "Toa nha Flemington",
            phoneNumber = "1231414",
            locationImage = {
            value = common.getPathToFileInStorage("icon.png"),
            imageType = "DYNAMIC"
            },
            searchAddress = {
            countryName = "aaa",
            countryCode = "084",
            postalCode = "test",
            administrativeArea = "aa",
            subAdministrativeArea = "a",
            locality = "a",
            subLocality = "a",
            thoroughfare = "a",
            subThoroughfare = "a"      
            }
        }  
    }
}

--[[ Local Functions ]]
local function pTUpdateFunc(tbl)
    local OWgroup = {
        rpcs = {
            GetWayPoints = {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
            },
            SubscribeWayPoints = {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
            },
            UnsubscribeWayPoints = {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
            },
            OnWayPointChange =  {
                hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
            }
        }
    }
    tbl.policy_table.functional_groupings["NewTestCaseGroup"] = OWgroup
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups = {"Base-4", "NewTestCaseGroup"}
    tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID]
    tbl.policy_table.app_policies[config.application3.registerAppInterfaceParams.appID] = tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID]
end

local function subscribeWayPoints1(pApp)
    local cid = common.getMobileSession(pApp):SendRPC("SubscribeWayPoints", {})
    common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
    common.getMobileSession(pApp):ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
    common.getMobileSession(pApp):ExpectNotification("OnHashChange")
end
local function subscribeWayPoints2(pApp)
    local cid = common.getMobileSession(pApp):SendRPC("SubscribeWayPoints", {})
    common.getMobileSession(pApp):ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
    common.getMobileSession(pApp):ExpectNotification("OnHashChange")
end

local function onWayPointChange()
    common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", notifParams)
    common.getMobileSession(1):ExpectNotification("OnWayPointChange", notifParams)
    common.getMobileSession(2):ExpectNotification("OnWayPointChange", notifParams)
  end

  local function subscribeWayPoints3(pApp)
    local cid = common.getMobileSession(pApp):SendRPC("SubscribeWayPoints", {})
    common.getMobileSession(pApp):ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
    common.getMobileSession(pApp):ExpectNotification("OnWayPointChange", notifParams)
    common.getMobileSession(pApp):ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Step("Register App 1", common.registerApp, { 1 })
runner.Step("RAI, PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App 1", common.activateApp, { 1 })
runner.Step("SubscribeWayPoints 1", subscribeWayPoints1, { 1 })

runner.Step("Register App 2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("SubscribeWayPoints 2", subscribeWayPoints2, { 2 })

-- [[ Test ]]
runner.Title("Test")
runner.Step("On Way Point Change (SDL send forward for all subscribed App)", onWayPointChange)
runner.Step("Register App 3", common.registerAppWOPTU, { 3 })
runner.Step("Activate App 3", common.activateApp, { 3 })
runner.Step("SubscribeWayPoints 3 (SDL send OnWayPointChanges for new subscribed App)", subscribeWayPoints3, { 3 })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
