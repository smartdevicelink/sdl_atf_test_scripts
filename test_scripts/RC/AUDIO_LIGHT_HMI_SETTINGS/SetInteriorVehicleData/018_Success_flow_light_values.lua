---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) Application is registered with REMOTE_CONTROL appHMIType
-- 2) and sends valid SetInteriorVehicleData RPC with valid parameters
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) Respond with <result_code> received from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module = "LIGHT"

--[[ Local Functions ]]
local function setInteriorVehicleData(pLightName)
  local rpc = "SetInteriorVehicleData"
  local mobSession = common.getMobileSession()

  local requestParams = common.getAppRequestParams(rpc, Module)
  requestParams.moduleData.lightControlData.lightState[1].id = pLightName

  local requestHMIParams = common.getHMIRequestParams(rpc, Module, 1)
  requestHMIParams.moduleData.lightControlData.lightState[1].id = pLightName

  local responseHMIParams = common.getHMIResponseParams(rpc, Module)
  responseHMIParams.moduleData.lightControlData.lightState[1].id = pLightName

  local cid = mobSession:SendRPC(common.getAppEventName(rpc), requestParams)
  EXPECT_HMICALL(common.getHMIEventName(rpc), requestParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseHMIParams)
  end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", moduleData = responseHMIParams.moduleData })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, lightName in pairs(common.LightsNameList) do
  runner.Step("SetInteriorVehicleData Light name " .. lightName, setInteriorVehicleData, { lightName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
