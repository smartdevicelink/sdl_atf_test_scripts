---------------------------------------------------------------------------------------------------
-- Common module for tests of https://github.com/SmartDeviceLink/sdl_core/issues/3931 issue
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = { }

--[[ Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.start = actions.start
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.getHMIConnection = actions.getHMIConnection
m.getMobileSession = actions.getMobileSession

--[[ Common Variables ]]
m.generatedGlobalProperties = {
    vrHelp = {},
    helpPrompt = {}
}

m.defaultINIGlobalProperties = {
    vrHelpTitle = "Available Vr Commands List",
    helpPrompt = {
        {text = "Please speak one of the following commands,", type = "TEXT"},
        {text = "Please say a command,", type = "TEXT"}
    }
}
--[[ Local Functions ]]
local function isItemInArray(pItem, pArray)
    for _, i in pairs(pArray) do
      if i == pItem then return true end
    end
    return false
end

local function getResetVRHelpItems()
    vrHelpItems = {{position = 1, text = "Test Application"}}
    for index, item in pairs(m.generatedGlobalProperties.vrHelp) do
        table.insert(vrHelpItems, {position = index + 1, text = item.text})
    end
    return vrHelpItems
end

--[[ Common Functions ]]
function m.AddCommand(pParams)
    local cid = m.getMobileSession():SendRPC("AddCommand", pParams)
    if pParams.menuParams then
        m.getHMIConnection():ExpectRequest("UI.AddCommand", {
            cmdID = pParams.cmdID,
            menuParams = pParams.menuParams
        })
        :Do(function(_, data)
            m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
    if pParams.vrCommands then
        m.getHMIConnection():ExpectRequest("VR.AddCommand", {
            cmdID = pParams.cmdID,
            vrCommands = pParams.vrCommands
        })
        :Do(function(_, data)
            m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)

        table.insert(m.generatedGlobalProperties.vrHelp, { position = (#m.generatedGlobalProperties.vrHelp + 1), text = pParams.vrCommands[1] })
        table.insert(m.generatedGlobalProperties.helpPrompt, { text = pParams.vrCommands[1], type = "TEXT" })
        m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", {
        vrHelp = m.generatedGlobalProperties.vrHelp
        })
        :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
        m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", {
        helpPrompt = m.generatedGlobalProperties.helpPrompt
        })
        :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
    
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end
  
function m.SetGlobalProperties(pParams)
    local cid = m.getMobileSession():SendRPC("SetGlobalProperties", pParams)
    if pParams.vrHelp or pParams.vrHelpTitle then
        m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", {
            vrHelp = pParams.vrHelp,
            vrHelpTitle = pParams.vrHelpTitle
        })
        :Do(function(_, data)
            m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
    if pParams.helpPrompt then
        m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", {
            helpPrompt = pParams.helpPrompt
        })
        :Do(function(_, data)
            m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })  
end
  
function m.ResetGlobalProperties(pParams)
    local cid = m.getMobileSession():SendRPC("ResetGlobalProperties", pParams)
    if isItemInArray("VRHELPITEMS", pParams.properties) or isItemInArray("VRHELPTITLE", pParams.properties) then
        m.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", {
            vrHelp = getResetVRHelpItems(),
            vrHelpTitle = m.defaultINIGlobalProperties.vrHelpTitle
        })
        :Do(function(_, data)
            m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end
    if isItemInArray("HELPPROMPT", pParams.properties) then
        m.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", {
            helpPrompt = m.defaultINIGlobalProperties.helpPrompt
        })
        :Do(function(_, data)
            m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end

    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

end



return m
