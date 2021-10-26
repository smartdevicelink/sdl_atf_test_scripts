---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3170
---------------------------------------------------------------------------------------------------
-- Description: Processing of 'AddCommand' and 'DeleteCommand' RPCs multiple times
--
-- Preconditions:
-- 1. Clean environment
-- 2. SDL, HMI, Mobile session are started
-- 3. App is registered
-- 4. App is activated
-- Steps:
-- 1. Send AddCommand mobile RPC with "vrCommands" and "menuParams" data from App
-- SDL does:
-- - transfer the UI part of request to HMI
-- - transfer the VR part of request to HMI
-- 2. HMI sends UI and VR part of response with "SUCCESS" result code
-- SDL does:
-- - send AddCommand response with (resultCode: SUCCESS, success:true) to mobile App
-- 3. Send DeleteCommand mobile RPC with "vrCommands" and "menuParams" data from App
-- SDL does:
-- - transfer the UI part of request to HMI
-- - transfer the VR part of request to HMI
-- 4. HMI sends UI and VR part of response with "SUCCESS" result code
-- SDL does:
-- - send DeleteCommand response with (resultCode: SUCCESS, success:true) to mobile App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local numOfItr = 50
local numOfCmds = 50

--[[ Local Functions ]]
local function getParams(pCmdId)
  return {
    cmdID = pCmdId,
    menuParams = {
      position = pCmdId,
      menuName ="Commandpositive_" .. pCmdId
    },
    vrCommands = {
      "VRCommandonepositive_" .. pCmdId
    }
  }
end

local function addCommands(pShift)
  for i = 1, numOfCmds do
    local cid = common.getMobileSession():SendRPC("AddCommand", getParams(pShift + i))
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :Timeout(20000)
  end
  common.getHMIConnection():ExpectRequest("UI.AddCommand"):Times(numOfCmds)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("VR.AddCommand"):Times(numOfCmds)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function deleteCommands(pShift)
  for i = 1, numOfCmds do
    local cid = common.getMobileSession():SendRPC("DeleteCommand", { cmdID = pShift + i })
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :Timeout(20000)
  end
  common.getHMIConnection():ExpectRequest("UI.DeleteCommand"):Times(numOfCmds)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("VR.DeleteCommand"):Times(numOfCmds)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for i = 1, numOfItr do
  runner.Title("Iteration " .. i)
  runner.Step("Add Commands", addCommands, { i*10 })
  runner.Step("Delete Commands", deleteCommands, { i*10 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
