---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. In .ini file GetInteriorVehicleDataRequest = 3, 11
-- 2. Mobile app sends 3 GetInteriorVD(module_1, without subscribe parameter) requests per 8 sec
-- 3. Mobile app starts sends a lot of requests before 1st success request processing
-- SDL must
-- 1. process successful 3 requests per 8 sec and send GetInteriorVD requests to HMI
-- 2. rejects requests starting from 4th one
-- 3. when time between received request and 1st success request is more then 11 sec process request successful and send GetInteriorVD requests to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables]]
local timestampArray = {}

-- [[ Local Functions]]
local function GetInteriorVehicleData(pModuleType, pRequestNubmer)
  local rpc = "GetInteriorVehicleData"
  local subscribe = nil
  local mobSession = common.getMobileSession(1)
  local cid = mobSession:SendRPC(common.getAppEventName(rpc),
    common.getAppRequestParams(rpc, pModuleType, subscribe))

  local hmiRequestParams = common.getHMIRequestParams(rpc, pModuleType, 1, subscribe)
  timestampArray[pRequestNubmer] = timestamp()
  hmiRequestParams.subscribe = nil
  EXPECT_HMICALL(common.getHMIEventName(rpc), hmiRequestParams)
  :Do(function(_, data)
	    local hmiResponseParams = common.getHMIResponseParams(rpc, pModuleType, subscribe)
	    hmiResponseParams.subscribe = nil
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseParams)
    end)
  :ValidIf(function(_, data)
      if data.params.subscribe then
        return false, "RC.GetInteriorVehicleData request contains unexpected 'subscribe' parameter"
      end
      return true
    end)
  mobSession:ExpectResponse(cid, common.getAppResponseParams(rpc, true, "SUCCESS", pModuleType, subscribe))
end

local function GetInteriorVehicleDataRejectedSuccess(pModuleType, pCompareRequest)
  local rpc = "GetInteriorVehicleData"
  local subscribe = nil
  local mobSession = common.getMobileSession(1)
  local function request()
	mobSession:SendRPC(common.getAppEventName(rpc),
	  common.getAppRequestParams(rpc, pModuleType, subscribe))
  end

  request()

  local hmiRequestParams = common.getHMIRequestParams(rpc, pModuleType, 1, subscribe)
  hmiRequestParams.subscribe = nil
  EXPECT_HMICALL(common.getHMIEventName(rpc), hmiRequestParams)
  :Do(function(_, data)
	  timestampArray[4] = timestamp()
	  local hmiResponseParams = common.getHMIResponseParams(rpc, pModuleType, subscribe)
	  hmiResponseParams.subscribe = nil
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResponseParams)
      common.wait(2000)
    end)

  mobSession:ExpectAny()
  :ValidIf(function(_, data)
      if data.rpcFunctionId == common.functionId[rpc] then
        if data.payload.resultCode == "SUCCESS" then
          local timeToRequest = {
            [1] = timestampArray[4] - timestampArray[1],
            [2] = timestampArray[4] - timestampArray[2],
            [3] = timestampArray[4] - timestampArray[3]
          }
          if timeToRequest[pCompareRequest] >= 11000 and
            timeToRequest[pCompareRequest] < 11700 then
            return true
          else
            return false, "Time to first success request after " .. pCompareRequest .. " request is not 11 seconds.\n" ..
            "Actual result: time to first request " .. timeToRequest[1] .. "\n" ..
            "time to second request " .. timeToRequest[2] .. "\n" ..
            "time to third request " .. timeToRequest[3] .. "\n"
          end
        else
          RUN_AFTER(request, 100)
        end
        return true
      else
        return false, "Unexpected rpc " .. data.rpcFunctionId .. " came"
      end
    end)
  :Times(AnyNumber())
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update GetInteriorVehicleDataRequest=3,11", common.setGetInteriorVehicleDataRequestValue, {"3,11"})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerAppWOPTU, { 1 })
runner.Step("Activate app", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("GetInteriorVehicleData without subscribe parameter " .. 1, GetInteriorVehicleData,
  {"CLIMATE", 1 })
runner.Step("Wait 5 secs", common.wait, { 5000 })
runner.Step("GetInteriorVehicleData without subscribe parameter " .. 2, GetInteriorVehicleData,
  {"CLIMATE", 2 })
runner.Step("Wait 3 secs", common.wait, { 3000 })
runner.Step("GetInteriorVehicleData without subscribe parameter " .. 3, GetInteriorVehicleData,
  {"CLIMATE", 3 })
runner.Step("GetInteriorVehicleData without subscribe parameter rejected before 11 seconds to 1st request",
	GetInteriorVehicleDataRejectedSuccess, { "CLIMATE", 1 })
runner.Step("GetInteriorVehicleData without subscribe parameter rejected before 11 seconds to 2st request",
	GetInteriorVehicleDataRejectedSuccess, { "CLIMATE", 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
