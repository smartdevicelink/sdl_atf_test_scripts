---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1878
--
-- Description:
-- SDL does not restore AddCommands in the same order as they were created by mobile app
--
-- Steps:
-- 1) App is registered and activated.
-- 2) App successfully added some AddCommands
-- 3) Ign off –> Ign on
-- 4) App registers -> SDL successfully performs HMILevel resumption and data resumption
--
-- Expected result:
-- 1) SDL must generate <internal_consecutiveNumber>
-- and assign this <internal_consecutiveNumber> to each AddCommand requested by app
-- 2) Restore AddCommand by this <internal_consecutiveNumber> during data resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashID

local addCommands = {
  {
    cmdID = 1,
    menuParams = {
      position = 0,
      menuName ="Command1"
    },
    vrCommands = {
      "VRCommand1"
    }
  },
  {
    cmdID = 22,
    menuParams = {
      position = 0,
      menuName ="Command2"
    },
    vrCommands = {
      "VRCommand2"
    }
  },
  {
    cmdID = 3,
    menuParams = {
      position = 0,
      menuName ="Command3"
    },
    vrCommands = {
      "VRCommand3"
    }
  }
}

--[[ Local Functions ]]
local function addCommand(pParams)
  local cid = common.getMobileSession():SendRPC("AddCommand", pParams)
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashID = data.payload.hashID
    end)
end

local function registerWithResumption()
  config.application1.registerAppInterfaceParams.hashID = hashID
  common.registerAppWOPTU()
  common.getHMIConnection():ExpectRequest("VR.AddCommand",
    { vrCommands = addCommands[1].vrCommands },
    { vrCommands = addCommands[2].vrCommands },
    { vrCommands = addCommands[3].vrCommands })
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(3)
  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(3)
end

function common.ignitionOff()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      test.mobileSession[1] = nil
      StopSDL()
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
for key, value in pairs(addCommands) do
  runner.Step("AddCommand " .. key, addCommand, { value })
end
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Ignition On", common.start)

runner.Title("Test")
runner.Step("Registration with resumption", registerWithResumption)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
