---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App1 is subscribed to module_1 and added AddSubMenu
-- 2. App2 is subscribed to module_1
-- 3. Transport disconnect and reconnect are performed
-- 4. Apps reregister with actual HashId
-- 5. UI.AddSubMenu is sent from SDL to HMI during resumption for app1
-- 6. RC.GetInteriorVD(subscribe=true, module_1) is sent from SDL to HMI during resumption for app1
-- 7. HMI responds with success resultCode to RC.GetInteriorVD(subscribe=true, module_1) request
-- 8. SDL restores subscription for module_1 for app2 internally
-- 9. HMI responds with error resultCode to UI.AddSubMenu
-- SDL does:
-- 1. respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to app2
-- 2. process unsuccess response from HMI
-- 3. remove subscription for modult_1 for app1 internally
-- 4. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to app1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkResumptionData()
  EXPECT_HMICALL("RC.GetInteriorVehicleData",
   { moduleType = common.modules[1], subscribe = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { moduleData = common.getModuleControlData(data.params.moduleType), subscribe = true })
    end)
  EXPECT_HMICALL("UI.AddSubMenu")
  :Do(function(_, data)
      local function sendResponse()
        common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
      end
      RUN_AFTER(sendResponse, 5000)
    end)
end

local function reRegisterApps()
  local requestParams1 = common.cloneTable(common.getConfigAppParams(1))
  requestParams1.hashID = common.hashId[1]

  local requestParams2 = common.cloneTable(common.getConfigAppParams(2))
  requestParams2.hashID = common.hashId[2]

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, d1)
      if d1.params.appName == common.getConfigAppParams(1).appName then
        common.setHMIAppId(d1.params.application.appID, 1)
      else
        common.setHMIAppId(d1.params.application.appID, 2)
      end
      if exp.occurences == 1 then
        local corId2 = common.getMobileSession(2):SendRPC("RegisterAppInterface", requestParams2)
        common.getMobileSession(2):ExpectResponse(corId2, { success = true, resultCode = "SUCCESS" })
        :Timeout(4000)
      end
    end)
  :Times(2)

  local corId1 = common.getMobileSession(1):SendRPC("RegisterAppInterface", requestParams1)
  common.getMobileSession(1):ExpectResponse(corId1, { success = true, resultCode = "RESUME_FAILED" })

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(2) })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)

  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  :Times(2)

  checkResumptionData()
end

local function addSubMenu()
  local requestParams = {
    menuID = 1000,
    position = 500,
    menuName ="SubMenupositive"
  }
  local cid = common.getMobileSession():SendRPC("AddSubMenu", requestParams)

  EXPECT_HMICALL("UI.AddSubMenu")
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_,data)
      common.hashId[1] = data.payload.hashID
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU)
runner.Step("App2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App1 activation", common.activateApp, { 1 })
runner.Step("App2 activation", common.activateApp, { 2, "NOT_AUDIBLE" })
runner.Step("Add AddSubMenu for app1", addSubMenu)
runner.Step("Add interiorVD subscription for " .. common.modules[1] .. " for app1",
  common.GetInteriorVehicleData, { common.modules[1], true, 1, 1 })
runner.Step("Add interiorVD subscription for " .. common.modules[1] .. " for app2",
  common.GetInteriorVehicleData, { common.modules[1], true, 0, 1, 2 })

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Open service for app1", common.openRPCservice, { 1 })
runner.Step("Open service for app2", common.openRPCservice, { 2 })
runner.Step("Reregister App resumption data", reRegisterApps)
runner.Step("Check subscription for app1", common.GetInteriorVehicleData, { common.modules[1], false, 0, 0 })
runner.Step("Check subscription for app2", common.GetInteriorVehicleData, { common.modules[1], false, 1, 1, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

