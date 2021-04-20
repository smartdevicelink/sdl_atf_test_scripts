---------------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/smartdevicelink/sdl_core/issues/974
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local actions = require("user_modules/sequences/actions")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local test = require("user_modules/dummy_connecttest")
local SDL = require("SDL")

--[[ Conditions to skip test ]]
if config.defaultMobileAdapterType ~= "TCP" then
  runner.skipTest("Test is applicable only for TCP connection")
end

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local deviceParams = {
  id = utils.getDeviceMAC(),
  name = "127.0.0.1:12345",
  transportType = "WIFI"
}

--[[ Local Functions ]]
local function getUpdatedDeviceList(pExp)
  if SDL.buildOptions.webSocketServerSupport == "ON" then
    local weDevice = {
      name = "Web Engine",
      transportType = "WEBENGINE_WEBSOCKET"
    }
    local pos = 1
    if pExp[pos] ~= nil then
      table.insert(pExp, pos, weDevice)
    else
      pExp[pos] = weDevice
    end
  end
  return pExp
end

local function start()
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          utils.cprint(35, "HMI initialized")
          test:initHMI_onReady()
          :Do(function()
              utils.cprint(35, "HMI is ready")
            end)
        end)
    end)
end

local function ConnectDeviceNonEmptyDeviceList()
  test:connectMobile()

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
	  deviceList = getUpdatedDeviceList({
	    deviceParams
	  })
	})
  :Do(function(_,data)
    actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

local function UpdateDeviceListNonEmptyDeviceList()
  local hmiConnection = actions.getHMIConnection()
  hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
	  deviceList = getUpdatedDeviceList({
	    deviceParams
	  })
	})
  :DoOnce(function(_,data)
	hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

	hmiConnection:SendNotification("BasicCommunication.OnDeviceChosen", {
		deviceInfo = {
			id = data.params.deviceList[1].id,
			name = data.params.deviceList[1].name
		}
	})

	hmiConnection:SendNotification("BasicCommunication.OnFindApplications", {
		deviceInfo = {
			id = data.params.deviceList[1].id,
			name = data.params.deviceList[1].name
		}
	})
  end)
  :ValidIf(function(_,data)
	if #data.params.deviceList ~= #getUpdatedDeviceList({ deviceParams }) then
	  commonFunctions:userPrint(31, "deviceList array in UpdateDeviceList contains not one device in list." ..
		" Received elements number '" .. tostring(#data.params.deviceList) .. "'")
	  return false
	else
	  return true
	end
  end)

  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :ValidIf(function(_,data)
	  if #data.params.applications ~= 0 then
	    commonFunctions:userPrint(31, "Number of applications in UpdateAppList in not 0, received number '" ..
	    tostring(#data.params.applications) .. "'")
	    return false
	  else return true
	  end
    end)
    :Times(AtMost(1))
end

local function CloseConnection()
  test.mobileConnection:Close()
end

local function UpdateDeviceListEmptyDeviceListAfterConnectionIsClosed()
  local hmiConnection = actions.getHMIConnection()
  hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
	:Do(function(_,data)
	  hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
    if #data.params.deviceList ~= #getUpdatedDeviceList({ }) then
		return false, "deviceList array in UpdateDeviceList is not empty. Received elements number '" ..
		  tostring(#data.params.deviceList) .. "'"
	  else
		return true
	  end
	end)

end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Start SDL, HMI", start)

runner.Title("Test")
runner.Step("Connect device", ConnectDeviceNonEmptyDeviceList)
runner.Step("Discover device after device connect", UpdateDeviceListNonEmptyDeviceList)
runner.Step("Close Connection", CloseConnection)
runner.Step("Discover device after device disconnect", UpdateDeviceListEmptyDeviceListAfterConnectionIsClosed)

runner.Title("Postconditions")
runner.Step("Stop SDL", actions.postconditions)
