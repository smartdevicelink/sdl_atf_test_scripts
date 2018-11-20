---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local json = require("modules/json")
local hmi_values = require('user_modules/hmi_values')

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Variables ]]
local m = actions

--[[ Functions]]
function m.readHmiCapabilities()
    local path_to_file = config.pathToSDL .. "/hmi_capabilities.json"
    local file  = io.open(path_to_file, "r")
    local json_data = file:read("*all")
    file:close()

    local capabilities = json.decode(json_data)
    local hmiCapabilities = {
        diagonalScreenSize = capabilities.UI.systemCapabilities.videoStreamingCapability.diagonalScreenSize,
        pixelPerInch = capabilities.UI.systemCapabilities.videoStreamingCapability.pixelPerInch,
        scale = capabilities.UI.systemCapabilities.videoStreamingCapability.scale
    }
    return hmiCapabilities
end

function m.updateHMIValue(pDiagonalSize, pPixelPerInch, pScale)
    local hmiValues = hmi_values.getDefaultHMITable()
    hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.diagonalScreenSize = pDiagonalSize
    hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.pixelPerInch = pPixelPerInch
    hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.scale = pScale
    return hmiValues
end

function m.getSystemCapability(pDiagonalSize, pPixelPerInch, pScale)
    local corId = m.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "VIDEO_STREAMING" })
    m.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS",
        systemCapability = {
            videoStreamingCapability = {
                supportedFormats = {
                    {codec = "H264",
                    protocol= "RAW"}
                },
                preferredResolution = {
                    resolutionHeight = 350,
                    resolutionWidth = 800
                },
                scale = pScale,
                pixelPerInch = pPixelPerInch,
                diagonalScreenSize = pDiagonalSize,
                maxBitrate = 10000,
                hapticSpatialDataSupported = false
            },
        systemCapabilityType = "VIDEO_STREAMING"}
    })
    :ValidIf(function(_, data)
        if pDiagonalSize == nil and data.payload.systemCapability.videoStreamingCapability.diagonalScreenSize ~= nil then
            return false, "Unexpected DiagonalSize parameter in GetSystemCapability responce"
        elseif pPixelPerInch == nil and data.payload.systemCapability.videoStreamingCapability.pixelPerInch ~= nil then
            return false, "Unexpected PixelPerInch parameter in GetSystemCapability responce"
        elseif pScale == nil and data.payload.systemCapability.videoStreamingCapability.scale ~= nil then
            return false, "Unexpected Scale parameter in GetSystemCapability responce"
        end
        return true
    end)
end

return m
