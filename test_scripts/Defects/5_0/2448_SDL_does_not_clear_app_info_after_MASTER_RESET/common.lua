--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local sdl = require("SDL")

--[[ Module ]]
local m = actions

function m.ignitionOff()
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    sdl:DeleteFile()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getMobileSession(1):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      sdl:StopSDL()
    end)
  end)
end

function m.waitUntilResumptionDataIsStored()
  utils.wait(10000)
end

function m.HMISendToSDL_MASTER_RESET()
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "MASTER_RESET" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose",{})
  :ValidIf(function()
    local app_info_table = utils.jsonFileToTable(commonPreconditions:GetPathToSDL()  .. "app_info.dat")
    local resumption_data = app_info_table.resumption.resume_app_list
    if next(resumption_data) == nil then
      return true
    else
      return false, "Resumption data is not cleared after MASTER_RESET"
    end
  end)
end

return m