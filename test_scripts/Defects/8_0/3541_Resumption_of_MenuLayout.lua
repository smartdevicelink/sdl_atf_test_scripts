---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3541
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. App sets menu layout through 'SetGlobalProperties'
-- 2. App adds sub menu with menu layout through 'AddSubMenu'
-- 3. App unexpectedly disconnects and reconnects with correct 'hashId'
--
-- SDL does:
--  - start data resumption process and send 'UI.SetGlobalProperties' and 'UI.AddSubMenu' requests to HMI
--  - both requests contains 'menuLayout' parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashId
local sgpParams = {
  menuTitle = "menuTitle",
  menuLayout = "TILES"
}
local asmParams = {
  menuLayout = "TILES",
  menuID = 44991234,
  menuName = "menuName"
}

--[[ Local Functions ]]
local function sendWindowCapabilities()
  local onSysCaps = {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          windowCapabilities = {
            {
              menuLayoutsAvailable = { "LIST", "TILES" }
            }
          }
        }
      }
    },
    appID = common.app.getHMIId()
  }
  common.hmi.getConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", onSysCaps)
end

local function sendSetGP()
  common.mobile.getSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
  local dataToHMI = utils.cloneTable(sgpParams)
  dataToHMI.appID = common.app.getHMIId()
  local cid = common.mobile.getSession():SendRPC("SetGlobalProperties", sgpParams)
  common.hmi.getConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMI)
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function sendAddSubMenu()
  common.mobile.getSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId = data.payload.hashID
    end)
  local dataToHMI = {
    menuID = asmParams.menuID,
    menuLayout = asmParams.menuLayout,
    menuParams = {
      menuName = asmParams.menuName
    }
  }
  dataToHMI.appID = common.app.getHMIId()
  local cid = common.mobile.getSession():SendRPC("AddSubMenu", asmParams)
  common.hmi.getConnection():ExpectRequest("UI.AddSubMenu", dataToHMI)
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function unexpectedDisconnect()
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  common.mobile.disconnect()
  common.run.wait(1000)
end

local function reRegisterApp()
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
    local appParams = utils.cloneTable(common.app.getParams())
    appParams.hashID = hashId
    local cid = session:SendRPC("RegisterAppInterface", appParams)
    common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    :Do(function()
        local dataToHMIsgp = utils.cloneTable(sgpParams)
        dataToHMIsgp.appID = common.app.getHMIId()
        common.hmi.getConnection():ExpectRequest("UI.SetGlobalProperties", dataToHMIsgp)
        :Do(function(_, data)
            common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          end)
        local dataToHMIasm = {
          menuID = asmParams.menuID,
          menuLayout = asmParams.menuLayout,
          menuParams = {
            menuName = asmParams.menuName
          }
        }
        dataToHMIasm.appID = common.app.getHMIId()
        common.hmi.getConnection():ExpectRequest("UI.AddSubMenu", dataToHMIasm)
        :Do(function(_, data)
            common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          end)
        sendWindowCapabilities()
      end)
    session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.app.register)
runner.Step("Send window capabilities", sendWindowCapabilities)
runner.Step("Activate App", common.app.activate)

runner.Title("Test")
runner.Step("App sends SetGP", sendSetGP)
runner.Step("App sends AddSubMenu", sendAddSubMenu)
runner.Step("Unexpected disconnect", unexpectedDisconnect)
runner.Step("Connect mobile", common.mobile.connect)
runner.Step("Re-register App", reRegisterApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
