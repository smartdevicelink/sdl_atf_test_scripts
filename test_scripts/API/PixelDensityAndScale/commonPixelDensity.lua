---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local json = require("modules/json")

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Variables ]]
local m = actions

local HmiCapabilities_file = config.pathToSDL .. "/hmi_capabilities.json"
m.f = assert(io.open(HmiCapabilities_file, "r"))
m.fileContent = m.f:read("*all")
m.f:close()

local HmiCapabilities = json.decode(m.fileContent)
m.defaultValue = {
    diagonalScreenSize = HmiCapabilities.UI.systemCapabilities.videoStreamingCapability.diagonalScreenSize,
    pixelPerInch = HmiCapabilities.UI.systemCapabilities.videoStreamingCapability.pixelPerInch,
    scale = HmiCapabilities.UI.systemCapabilities.videoStreamingCapability.scale
}

--[[ Functions]]
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
end

return m