---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Requirement summary:
-- 1. HMI sends invalid response to SDL
-- 2. SDL responds GENERIC_ERROR, success:false
--
-- Description:
-- SDL responds GENERIC_ERROR, success:false in case of receiving invalid response from HMI
--
-- Steps:
-- App requests GetWayPoints
-- HMI responds with invalid respone(mandatory missing, invalid json, invalid struct of json, invalid value of parametes)
--
-- Expected:
-- SDL responds GENERIC_ERROR, success:false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local json = require("json")

--[[ Local Variables ]]
local HMIresponses = {
    method_Missing = { jsonrpc = "2.0", result = { code = 0 }},
    method_WrongType = { jsonrpc = "2.0", result = { method = 3 ,code = 0 }},
    method_WrongValue = { jsonrpc = "2.0", result = { method = "ANY" ,code = 0 }},
    method_AnotherRPC = { jsonrpc = "2.0", result = { method = "Navigation.ShowConstantTBT", code = 0 }},
    method_newLine = { jsonrpc = "2.0", result = { method = "Navigation.GetWayPoints\n", code = 0 }},
    method_Tab = { jsonrpc = "2.0", result = { method = "Navigation.\tGetWayPoints", code = 0 }},
    method_WhiteSpaceOnly = { jsonrpc = "2.0", result = { method = " ", code = 0 }},
    code_Missing = { jsonrpc = "2.0", result = { method = "Navigation.GetWayPoints" }},
    code_WrongType = { jsonrpc = "2.0", result = { method = "Navigation.GetWayPoints", code = "0" }},
    code_WrongValue = { jsonrpc = "2.0", result = { method = "Navigation.GetWayPoints", code = 1111 }},
    result_Missing = { jsonrpc = "2.0" },
    result_WrongType = { jsonrpc = "2.0", result = 0 }
}

local HMIresponsesIdCheck = {
    id_Missing = { jsonrpc = "2.0", result = { method = "Navigation.GetWayPoints", code = 0 }},
    id_WrongType = { jsonrpc = "2.0", id = "35", result = { method = "Navigation.GetWayPoints", code = 0 }},
    id_WrongValue = { jsonrpc = "2.0", id = 1111, result = { method = "Navigation.GetWayPoints", code = 0 }},
}

--[[ Local Functions ]]
local function GetWayPoints(paramsResponse, idValue, self)
    local params = {
	    wayPointType = "ALL"
	  }
    local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
    EXPECT_HMICALL("Navigation.GetWayPoints")
    :Do(function(_,data)
        local text
        if type(paramsResponse) ~= "string" then
            if idValue == true then
                paramsResponse.id = data.id
            end
            if paramsResponse.result then
                paramsResponse.result.appID = common.getHMIAppId()
            end
            text = json.encode(paramsResponse)
        else
            local appIdValue = common.getHMIAppId()
            text ='{"id":'..data.id..',' .. paramsResponse .. appIdValue .. '}}'
        end
        self.hmiConnection:Send(text)
    end)
    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for key, value in pairs(HMIresponses) do
    runner.Step("GetWayPoints_" .. tostring(key), GetWayPoints, { value, true })
end
runner.Step("GetWayPoints_invalid_json", GetWayPoints,
    -- missed ':'
	{ '"jsonrpc":"2.0","result":{"method""Navigation.GetWayPoints", "code":0, "appID":', false })
runner.Step("GetWayPoints_invalid_json_struct", GetWayPoints,
    -- code parameter is not in result struct
    { '"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.GetWayPoints", "appID":', false })
runner.Step("GetWayPoints_invalid_json_struct_with_result_and_error", GetWayPoints,
    -- code parameter is not in result struct
    { '"jsonrpc":"2.0", "error":{"code":4,"message":"GetWayPoints is REJECTED"}, "result":{"method":"Navigation.GetWayPoints", "code":0, "appID":', false })
for key, value in pairs(HMIresponsesIdCheck) do
    runner.Step("GetWayPoints_" .. tostring(key), GetWayPoints, { value, false })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
