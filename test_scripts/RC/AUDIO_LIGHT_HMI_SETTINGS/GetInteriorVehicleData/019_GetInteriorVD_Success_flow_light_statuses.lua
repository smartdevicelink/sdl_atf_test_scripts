---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description: TRS: GetInteriorVehicleData, #3
-- In case:
-- 1) RC app sends valid and allowed by policies GetInteriorvehicleData_request
-- 2) and SDL received GetInteriorVehicledata_response with successful result code and current module data from HMI
-- SDL must:
-- 1) transfer GetInteriorVehicleData_response with provided from HMI current module data for allowed module and control items
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module =  "LIGHT"

--[[ Local Functions ]]
local function subscribeToModule(pStatus)
  local rpc = "GetInteriorVehicleData"
  local subscribe = false
  local mobSession = common.getMobileSession()

  local reguestHMIParams = common.getHMIRequestParams(rpc, Module, 1, subscribe)
  reguestHMIParams.subscribe = nil

  local responseHMIParams = common.getHMIResponseParams(rpc, Module, subscribe)
  responseHMIParams.moduleData.lightControlData.lightState[1].status = pStatus

  local responseParams = common.getAppResponseParams(rpc, true, "SUCCESS", Module, subscribe)
  responseParams.moduleData.lightControlData.lightState[1].status = pStatus

  local cid = mobSession:SendRPC(common.getAppEventName(rpc), common.getAppRequestParams(rpc, Module, subscribe))
  EXPECT_HMICALL(common.getHMIEventName(rpc), reguestHMIParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseHMIParams)
  end)
  mobSession:ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, status in pairs(common.readOnlyLightStatus) do
  runner.Step("GetInteriorVehicleData Light status " .. status, subscribeToModule, { status })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
