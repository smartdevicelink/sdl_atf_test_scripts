---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0083-Expandable-design-for-proprietary-data-exchange.md
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2716
--
-- In case:
-- 1. HMI sends BC.OnSystemRequest with `requestType` = OEM_SPECIFIC and not empty `fileName` parameters
--
-- SDL does:
-- 1. Read content of the file provided in `fileName`
-- 2. Send OnSystemRequest to mobile App with content of the file in `binaryData`
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Expanded_proprietary_data_exchange/commonDataExchange')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local content = "{\"key\":\"value\"}"
local file = os.tmpname()

--[[ Local Functions ]]
local function setContent()
  local f = io.open(file, "w")
  f:write(content)
  f:close()
end

local function removeTmpFile()
  os.remove(file)
end

local function onSystemRequest()
  setContent()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest", {
    requestType = "OEM_SPECIFIC",
    fileName = file,
  })
  common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "OEM_SPECIFIC" })
  :ValidIf(function(_, d)
      if d.binaryData == content then
        return true
      end
      return false, "Content of the file is not send in `binaryData`"
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("OnSystemRequest with request type OEM_SPECIFIC", onSystemRequest)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Remove temporary file", removeTmpFile)
