---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3909
---------------------------------------------------------------------------------------------------
-- Description:
-- Check that vrHelp items are saved and restored correctly after unexpected disconnect 
-- (after global properties are reset before app resumption)
--
-- Preconditions:
-- 1) SDL, HMI, Mobile session are started
-- 2) App is registered
-- 3) App sends SetGlobalProperties request with vrHelp and vrHelpTitle
-- 4) App sends ResetGlobalProperties request with VRHELPTITLE and VRHELPITEMS
-- SDL does:
--  - Send UI.SetGlobalProperties to the HMI with default values for vrHelp and vrHelpTitle
--  - Send OnHashChange notification to the app
--
-- Steps:
-- 1) App disconnects and reconnects
-- SDL does:
--  - Send UI.SetGlobalProperties to the HMI with default values for vrHelp and vrHelpTitle 
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashID = nil

local vrGlobalPropertyNames = { 
  "VRHELPTITLE", "VRHELPITEMS" 
}

local vrGlobalProperties = {
  vrHelpTitle = "title",
  vrHelp = {
    { text = "VR Help 1", position = 1 },
    { text = "VR Help 2", position = 2 }
  }
}

local defaultVrGlobalProperties = {
  vrHelpTitle = "Available Vr Commands List",
  vrHelp = {
    { text = common.getConfigAppParams().appName, position = 1 }
  }
}

--[[ Local Functions ]]
local function registerApp()
  common.app.getParams().hashID = nil
  common.app.registerNoPTU()
end

local function sendSetGlobalProperties(pParams)
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", pParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function sendResetGlobalProperties(pParams, pDefaultParamValues)
  	local cid = common.mobile.getSession():SendRPC("ResetGlobalProperties", {
  		properties = pParams
  	})
  
  	common.hmi.getConnection():ExpectRequest("UI.SetGlobalProperties", pDefaultParamValues)
  	:Do(function(_,data)
  		common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  	end)
    common.mobile.getSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  	common.mobile.getSession():ExpectNotification("OnHashChange")
    :Do(function(_, data)
      hashID = data.payload.hashID
    end)
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  common.mobile.disconnect()
  utils.wait(1000)
end

local function reRegisterApp(pParams)
  common.app.getParams().hashID = hashID
  common.app.registerNoPTU()
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", registerApp)
runner.Step("Set VR Global Properties", sendSetGlobalProperties, { vrGlobalProperties })
runner.Step("Reset VR Global Properties", sendResetGlobalProperties, { vrGlobalPropertyNames, defaultVrGlobalProperties })

runner.Title("Test vrHelp Resumption")
runner.Step("Unexpected Disconnect", unexpectedDisconnect)
runner.Step("Reconnect App", common.mobile.connect)
runner.Step("Re-register App", reRegisterApp, { defaultVrGlobalProperties })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
