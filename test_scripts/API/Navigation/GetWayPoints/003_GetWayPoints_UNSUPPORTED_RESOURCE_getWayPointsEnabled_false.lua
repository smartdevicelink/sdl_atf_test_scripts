---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 3: Exception 4: "getWayPointsEnabled": false in HMI capabilities
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid and allowed by Policies GetWayPoints_request to SDL and "getWayPointsEnabled": false in HMI capabilities
-- SDL must:
-- 1) respond "UNSUPPORTED_RESOURCE, success:false" to mobile application and not transfer this request to HMI

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local hmi_values = require('user_modules/hmi_values')

--[[ Local Functions ]]
local function disableGetWayPoints()
  local params = hmi_values.getDefaultHMITable()
  params.UI.GetCapabilities.params.systemCapabilities.navigationCapability.getWayPointsEnabled = false
  return params
end

local function getWayPoints(self)
  local params = {
    wayPointType = "ALL"
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
  common:DelayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { disableGetWayPoints() })
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints,\"getWayPointsEnabled\":false", getWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
