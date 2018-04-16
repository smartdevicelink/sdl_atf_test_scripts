
---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Variables ]]
local m = actions

function m.putFileParams()
  local temp = {
    syncFileName = "icon.png",
    fileType = "GRAPHIC_PNG",
  }
  return temp
end

local function bytesToInt(pStr)
  local t = { string.byte(pStr, 1, -1) }
  local n = 0
  for k = 1, #t do
    n = n + t[k] * 2 ^ ((k - 1) * 8)
  end
  return n
end

function m.getCheckSum(pFile)
  local cmd = "cat " .. pFile .. " | gzip -1 | tail -c 8 | head -c 4"
  local handle = io.popen(cmd)
  local crc = handle:read("*a")
  handle:close()
  return bytesToInt(crc)
end

function m.putFile(pParams, pFile, pResult)
  if not pResult then pResult = { success = true, resultCode = "SUCCESS" } end
  local mobSession = m.getMobileSession()
  local cid = mobSession:SendRPC("PutFile", pParams, pFile)
  mobSession:ExpectResponse(cid, pResult)
end

return m
