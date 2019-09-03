---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local hmi_values = require('user_modules/hmi_values')
local utils = require("user_modules/utils")
local actions = require("user_modules/sequences/actions")

--[[ Variables ]]
local m = actions

--[[ Functions]]
function m.hmiDefaultValues()
  local path_to_file = config.pathToSDL .. "/hmi_capabilities.json"
  local defaulValue = utils.jsonFileToTable(path_to_file)
  local hmiDefaultValues = {
    diagonalScreenSize = defaulValue.UI.systemCapabilities.videoStreamingCapability.diagonalScreenSize,
    pixelPerInch = defaulValue.UI.systemCapabilities.videoStreamingCapability.pixelPerInch,
    scale = defaulValue.UI.systemCapabilities.videoStreamingCapability.scale
  }
  return hmiDefaultValues
end

function m.getUpdatedHMIValues(pDiagonalSize, pPixelPerInch, pScale)
  local hmiValues = hmi_values.getDefaultHMITable()
  hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.diagonalScreenSize = pDiagonalSize
  hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.pixelPerInch = pPixelPerInch
  hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.scale = pScale
  return hmiValues
end

function m.getSystemCapability(pExpDiagonalSize, pExpPixelPerInch, pExpScale)
  local corId = m.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "VIDEO_STREAMING" })
  m.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS",
    systemCapability = {
      videoStreamingCapability = {
        scale = pExpScale,
        pixelPerInch = pExpPixelPerInch,
        diagonalScreenSize = pExpDiagonalSize
      },
    systemCapabilityType = "VIDEO_STREAMING"}
  })
  :ValidIf(function(_, data)
    if pExpDiagonalSize == nil and data.payload.systemCapability.videoStreamingCapability.diagonalScreenSize ~= nil then
      return false, "Unexpected DiagonalSize parameter in GetSystemCapability response"
    elseif pExpPixelPerInch == nil and data.payload.systemCapability.videoStreamingCapability.pixelPerInch ~= nil then
      return false, "Unexpected PixelPerInch parameter in GetSystemCapability response"
    elseif pExpScale == nil and data.payload.systemCapability.videoStreamingCapability.scale ~= nil then
      return false, "Unexpected Scale parameter in GetSystemCapability response"
    end
    return true
  end)
end

return m
