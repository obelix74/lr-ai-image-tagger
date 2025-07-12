--[[----------------------------------------------------------------------------

 AI Image Tagger - Automatically Tag Photos using Gemini AI API
 Copyright 2017-2024 Tapani Otala, Enhanced by Anand Kumar Sankaran
 Updated for Lightroom Classic 2024 and Gemini AI

--------------------------------------------------------------------------------

Info.lua
Summary information for the plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 13.0,
	LrSdkMinimumVersion = 10.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = "com.anands.lightroom.aiimagetagger",

	LrPluginName = LOC( "$$$/AiTagger/PluginName=AI Image Tagger" ),
	LrPluginInfoUrl = "https://github.com/obelix74/lr-ai-image-tagger",
	LrPluginInfoProvider = "AiTaggerInfoProvider.lua",

	LrInitPlugin = "AiTaggerInit.lua",
	LrShutdownPlugin = "AiTaggerShutdown.lua",

	-- Add the menu item to the File menu.

	LrExportMenuItems = {
		{
			title = LOC( "$$$/AiTagger/LibraryMenuItem=Tag Photos with AI" ),
			file = "AiTaggerMenuItem.lua",
			enabledWhen = "photosSelected",
		},
	},

	-- Add the menu item to the Library menu.

	LrLibraryMenuItems = {
		{
			title = LOC( "$$$/AiTagger/LibraryMenuItem=Tag Photos with AI" ),
			file = "AiTaggerMenuItem.lua",
			enabledWhen = "photosSelected",
		},
	},

	VERSION = { major = 2, minor = 0, revision = 0, build = 1, },

}
