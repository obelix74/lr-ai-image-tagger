--[[----------------------------------------------------------------------------

 Gemini AI Image Tagger - Automatically Tag Photos using Gemini AI API
 Copyright 2025 Anand's Photography
 Updated for Lightroom Classic 2024 and Gemini AI

--------------------------------------------------------------------------------

Info.lua
Summary information for the plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 13.0,
	LrSdkMinimumVersion = 10.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = "net.tagimg.gemini-lr-tagimg",

	LrPluginName = LOC( "$$$/AiTagger/PluginName=Gemini AI Image Tagger" ),
	LrPluginInfoUrl = "https://lr.tagimg.net",
	LrPluginInfoProvider = "AiTaggerInfoProvider.lua",

	LrInitPlugin = "AiTaggerInit.lua",
	LrShutdownPlugin = "AiTaggerShutdown.lua",

	-- Add the menu item to the File menu.

	LrExportMenuItems = {
		{
			title = LOC( "$$$/AiTagger/LibraryMenuItem=Tag Photos with Gemini AI" ),
			file = "AiTaggerMenuItem.lua",
			enabledWhen = "photosSelected",
		},
	},

	-- Add the menu item to the Library menu.

	LrLibraryMenuItems = {
		{
			title = LOC( "$$$/AiTagger/LibraryMenuItem=Tag Photos with Gemini AI" ),
			file = "AiTaggerMenuItem.lua",
			enabledWhen = "photosSelected",
		},
	},

	-- Custom plugin properties for AI metadata storage
	-- LrMetadataProvider = "AiTaggerMetadataProvider.lua",

	VERSION = { major = 3, minor = 5, revision = 0, build = 1, },

}
