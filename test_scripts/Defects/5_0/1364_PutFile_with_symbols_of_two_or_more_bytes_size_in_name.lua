---------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/smartdevicelink/sdl_core/issues/1364
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local FileName = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧС" ..
"СМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШО"..
"ЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМваaaa"

local putFileParams = {
  requestParams = {
      syncFileName = FileName,
      fileType = "GRAPHIC_PNG"
  },
  filePath = "files/icon.png"
}

--[[ Local Function ]]
local function PutFile()
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC("PutFile", putFileParams.requestParams, putFileParams.filePath)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerApp)
runner.Step("Activate app", common.activateApp)

runner.Title("Test")
runner.Step("PutFile", PutFile)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
