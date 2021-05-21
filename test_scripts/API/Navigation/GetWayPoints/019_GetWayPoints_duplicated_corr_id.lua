---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid and allowed by Policies GetWayPoints_requests with the same correlationId to SDL
-- SDL must:
-- 1) Transfer GetWayPoints_request to HMI
-- 2) Respond with <resultCode> received from HMI to mobile application
-- 3) Provide the requested parameters at the same order as received from HMI
--    to mobile application (in case of successfull response)

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function GetWayPoints(self)
	local params = {
		wayPointType = "ALL"
	}
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  print("MOB->SDL: RQ1")

  params.appID = common.getHMIAppId()
  local lResponse = { }
  lResponse.wayPoints = {{ locationName = "Hotel" }}
  lResponse.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :Do(function(exp,data)
      print("SDL->HMI: RQ" .. exp.occurences)
      local function request2()
        print("MOB->SDL: RQ2")
        local msg = {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 0,
          rpcFunctionId    = 45,
          rpcCorrelationId = cid,
          payload          = '{"wayPointType":"ALL"}'
        }
        self.mobileSession1:Send(msg)
      end
      if exp.occurences == 1 then
        RUN_AFTER(request2, 500)
      end
      local function response()
        print("HMI->SDL: RS" .. exp.occurences)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", lResponse)
      end
      RUN_AFTER(response, 100)
  end)
  :Times(2)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", wayPoints = lResponse.wayPoints })
  :Times(2)
  :Do(function(exp)
      print("SDL->MOB: RS" .. exp.occurences)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints_duplicated_correlation_id", GetWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
