---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Alternative flow 3)
--
-- Requirement summary:
-- App requests SendLocation with deliveryMode, other valid and allowed parameters
-- and without address, latitudeDegrees and longitudeDegrees
--
-- Description:
-- App sends SendLocation without addrress, longitudeDegrees or latitudeDegrees parameters.

-- In case:
-- 1) mobile application sends SendLocation_request with:
-- 2) one or more requested parameters allowed by Policies
-- 3) one or more requested parameters disallowed by Policies
-- 4) and this request is allowed by Policies for this mobile application
--
-- SDL must:
-- 1) transfer SendLocation with allowed parameters only to HMI
-- 2) respond with <received_resultCode_from_HMI> + success: (true OR false) + info:
-- " <param_A>, <param_B> parameters are disallowed by Policies"
-- NOTE:
-- in case with disallowed "deliveryMode" SDL must add to info also: "default value of deliveryMode will be used"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local requestParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  deliveryMode = "PROMPT",
  locationName = "1 American Rd"
}

local disallowedParams = { "deliveryMode", "locationName" }

--[[ Local Functions ]]
local function sendLocation(self)
  local mobileSession = commonSendLocation.getMobileSession(self, 1)
  local cid = self.mobileSession1:SendRPC("SendLocation", requestParams)
  EXPECT_HMICALL("Navigation.SendLocation", { longitudeDegrees = 1.1, latitudeDegrees = 1.1 })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
        { longitudeDegrees = 1.1, latitudeDegrees = 1.1 })
    end)
  :ValidIf(function(_, data)
      local notExpParams = {}
      for _, p in pairs(disallowedParams) do
        if data.params[p] then
          table.insert(notExpParams, p)
        end
      end
      if #notExpParams > 0 then
        return false, "Parameters [" .. table.concat(notExpParams, ", ") .. "] are not expected"
      end
      return true
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    info = "default value of delivery mode will be used, 'locationName' parameter is disallowed by Policies" })
end

local function pUpdateFunction(pTbl)
  local params = pTbl.policy_table.functional_groupings.SendLocation.rpcs.SendLocation.parameters
  commonSendLocation.filterTable(params, disallowedParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU, { 1, pUpdateFunction })
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", commonSendLocation.putFile, {"icon.png"})

runner.Title("Test")
runner.Step("SendLocation with both mandatory params and 2 disallowed:locationName and deliveryMode", sendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
