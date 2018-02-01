---------------------------------------------------------------------------------------------------
-- iAP2TransportSwitch common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.zeroOccurrenceTimeout = 1000

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local SDL = require("SDL")
local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
local mobile = require("mobile_connection")
local events = require("events")
local expectations = require('expectations')
local module = require("user_modules/dummy_connecttest")

--[[ Local Variables ]]
local Expectation = expectations.Expectation

local m = {}

m.device = {
  bluetooth = {
    id = "127.0.0.1",
    port = 23456,
    out = "iap2bt.out",
    type = "BLUETOOTH",
    uid = "127.0.0.1:23456"
  },
  usb = {
    id = "127.0.0.1",
    port = 34567,
    out = "iap2usb.out",
    type = "USB_IOS",
    uid = "127.0.0.1:34567"
  }
}

m.appParams = config["application1"].registerAppInterfaceParams

function module:start()
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady()
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
            end)
        end)
    end)
end

function module:waitForAllEvents(pTimeout)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_HMIEVENT(event, "Delayed event"):Timeout(pTimeout + 1000)
  local function toRun()
    event_dispatcher:RaiseEvent(self.hmiConnection, event)
  end
  RUN_AFTER(toRun, pTimeout)
end

function module:expectEvent(pEvent, pName, pDevice)
  local ret = Expectation(pName, pDevice)
  ret.event = pEvent
  event_dispatcher:AddEvent(pDevice, pEvent, ret)
  self:AddExpectation(ret)
  return ret
end

function module:createIAP2Device(pDeviceId, pDevicePort, pDeviceOut)
  local connection = tcp.Connection(pDeviceId, pDevicePort)
  local fileConnection = file_connection.FileConnection(pDeviceOut, connection)
  local device = mobile.MobileConnection(fileConnection)
  event_dispatcher:AddConnection(device)
  return device
end

function module:connectMobile(pDevice)
  module:expectEvent(events.disconnectedEvent, "Disconnected", pDevice)
  :Pin()
  :Times(AnyNumber())
  :Do(function()
      print("Device disconnected: " .. pDevice.connection.filename)
    end)
  pDevice:Connect()
  return module:expectEvent(events.connectedEvent, "Connected", pDevice)
end

function module:doTransportSwitch(device)
  local input = io.open(config.pathToSDL.."/iap_signals_in", "w")
  if not input then print("Input signals channel not opened") return end
  local input_signal = "SDL_TRANSPORT_SWITCH"
  input:write(input_signal)
  print("Signal "..input_signal.." sent")
  input:close()

  local output = io.open(config.pathToSDL.."/iap_signals_out", "r")
  if not output then print("Output signals channel not opened") return end
  print("Waiting for ACK")
  local out = output:read()
  print("Got signal: "..out)
  if out ~= "SDL_TRANSPORT_SWITCH_ACK" then print("Unexpected signal") return end
  output:close()

  device:Close()
end

function m.preconditions()
  local ptFileName = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local ptName = "files/jsons/sdl_preloaded_pt_all_allowed.json"
  commonFunctions:SDLForceStop()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
  commonPreconditions:BackupFile(ptFileName)
  os.execute("cp -f " .. ptName .. " " .. commonPreconditions:GetPathToSDL() .. "/" .. ptFileName)
  commonFunctions:SetValuesInIniFile("AppTransportChangeTimer%s-=%s-[%d]-%s-\n", "AppTransportChangeTimer", "5000")
end

function m.postconditions()
  SDL:StopSDL()
  local ptFileName = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:RestoreFile(ptFileName)
end

function m:start()
  module.start(self)
end

function m.print(pMsg)
  commonFunctions:userPrint(35, pMsg)
end

return m
