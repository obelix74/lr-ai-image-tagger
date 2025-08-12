--[[----------------------------------------------------------------------------

 AI Image Tagger - Automatically Tag Photos using AI
 Copyright 2025 Anand's Photography
 Updated for Lightroom Classic 2024 with Gemini AI and Ollama support

--------------------------------------------------------------------------------

Info.lua
Summary information for the plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 13.0,
	LrSdkMinimumVersion = 10.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = "net.tagimg.ai-lr-tagimg",

	LrPluginName = LOC( "$$$/AiTagger/PluginName=AI Image Tagger" ),
	LrPluginInfoUrl = "https://obelix74.github.io/lr-ai-image-tagger/",
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

	-- Custom plugin properties for AI metadata storage
	-- LrMetadataProvider = "AiTaggerMetadataProvider.lua",

	VERSION = { major = 4, minor = 0, revision = 2, build = 1, },

}
