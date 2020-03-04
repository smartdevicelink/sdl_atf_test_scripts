---------------------------------------------------------------------------------------------------
-- Common module for pcmStreamCapabilities
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local hmi_values = require('user_modules/hmi_values')
local runner = require('user_modules/script_runner')
local SDL = require('SDL')

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Common Variables ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.start = actions.start
m.postconditions = actions.postconditions
m.mobile = actions.getMobileSession
m.hmi = actions.hmi.getConnection
m.getAppParams = actions.app.getParams
m.closeSession = actions.mobile.closeSession
m.cloneTable = utils.cloneTable
m.spairs = utils.spairs

m.hmiDefaultCapabilities = hmi_values.getDefaultHMITable()

local defaultSDLcapabilities = SDL.HMICap.get()
m.defaultPcmStreamCapabilities = defaultSDLcapabilities.UI.pcmStreamCapabilities
for k, value in pairs(m.defaultPcmStreamCapabilities) do
  m.defaultPcmStreamCapabilities[k] = value:gsub("RATE_", "")
end

m.pcmStreamCapabilitiesValue = {
  samplingRate = "8KHZ",
  bitsPerSample = "8_BIT",
  audioType = "PCM"
}

--[[ Common Functions ]]
function m.registerApp(pPcmStreamCapabilityValue)
  local session = m.mobile(1)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", m.getAppParams())
      m.hmi():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getAppParams().appName } })
      session:ExpectResponse(corId, {
        success = true,
        resultCode = "SUCCESS",
        pcmStreamCapabilities = pPcmStreamCapabilityValue
      })
    end)
end

function m.setHMICapabilities(pPcmStreamCapabilities)
  m.hmiDefaultCapabilities.UI.GetCapabilities.params.pcmStreamCapabilities = pPcmStreamCapabilities
end

return m
