local testSettings = {
	description = "ATF test script",
	severity = "Major",
	restrictions = {
		sdlBuildOptions = {} -- no restrictions on SDL configuration
	},
	defaultTimeout = 11000,
	isSelfIncluded = true
}

return testSettings
