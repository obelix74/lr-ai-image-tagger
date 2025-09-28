--[[----------------------------------------------------------------------------

 AI Image Tagger
 Copyright 2025 Anand's Photography
 Updated for Lightroom Classic 2024

--------------------------------------------------------------------------------

AiTaggerInit.lua

------------------------------------------------------------------------------]]

local LrSystemInfo = import "LrSystemInfo"
local LrPrefs = import "LrPrefs"

--------------------------------------------------------------------------------

require "Logger"

--------------------------------------------------------------------------------

local prefs = LrPrefs.prefsForPlugin()

-- Plugin constants - now properly scoped as local variables
local decorateKeywordAsIs   = "keywordAsIs"
local decorateKeywordPrefix = "keywordPrefix"
local decorateKeywordSuffix = "keywordSuffix"
local decorateKeywordParent = "keywordParent"

local thresholdMin = 0
local thresholdMax = 100
local thresholdStep = 1

local tasksMin = 1
local tasksMax = LrSystemInfo.numCPUs()
local tasksStep = 1

if prefs.maxTasks == nil then
	prefs.maxTasks = math.min(tasksMax, 4) -- Limit to 4 concurrent requests for better stability
end

-- Export constants for use by other modules
-- This prevents global namespace pollution while maintaining accessibility
_G.AiTaggerConstants = {
	decorateKeywordAsIs = decorateKeywordAsIs,
	decorateKeywordPrefix = decorateKeywordPrefix,
	decorateKeywordSuffix = decorateKeywordSuffix,
	decorateKeywordParent = decorateKeywordParent,
	thresholdMin = thresholdMin,
	thresholdMax = thresholdMax,
	thresholdStep = thresholdStep,
	tasksMin = tasksMin,
	tasksMax = tasksMax,
	tasksStep = tasksStep
}

prefs.maxKeywords = 10
-- Increase thumbnail size for better accuracy with modern AI
prefs.thumbnailWidth = 1600
prefs.thumbnailHeight = 1600

-- Version migration logic
-- Track plugin version for future migrations
local CURRENT_PLUGIN_VERSION = "6.1.0"
if prefs.pluginVersion == nil then
	prefs.pluginVersion = CURRENT_PLUGIN_VERSION
end

-- Migrate Gemini 1.5 Flash users to 2.5 Flash (better performance, same cost)
if prefs.geminiModel == "gemini-1.5-flash" then
	logger:infof("Migrating Gemini model from 1.5 Flash to 2.5 Flash for better performance")
	prefs.geminiModel = "gemini-2.5-flash"
	prefs.pluginVersion = CURRENT_PLUGIN_VERSION
end

if prefs.decorateKeyword == nil then
	prefs.decorateKeyword = AiTaggerConstants.decorateKeywordAsIs
	prefs.decorateKeywordValue = nil
end

if prefs.saveTitleToIptc == nil then
	prefs.saveTitleToIptc = true
end

if prefs.saveCaptionToIptc == nil then
	prefs.saveCaptionToIptc = true
end

if prefs.saveHeadlineToIptc == nil then
	prefs.saveHeadlineToIptc = true
end

-- AI prompt customization
if prefs.customPrompt == nil then
	prefs.customPrompt = ""
end

if prefs.useCustomPrompt == nil then
	prefs.useCustomPrompt = false
end

-- Additional IPTC metadata options
if prefs.saveInstructionsToIptc == nil then
	prefs.saveInstructionsToIptc = false
end

if prefs.saveCopyrightToIptc == nil then
	prefs.saveCopyrightToIptc = false
end

if prefs.saveLocationToIptc == nil then
	prefs.saveLocationToIptc = false
end

if prefs.saveKeywordsToIptc == nil then
	prefs.saveKeywordsToIptc = false  -- Disabled by default due to Lightroom SDK limitations
end

-- Batch processing options
if prefs.batchSize == nil then
	prefs.batchSize = 5
end

if prefs.delayBetweenRequests == nil then
	prefs.delayBetweenRequests = 1000 -- milliseconds
end

-- GPS and EXIF metadata sharing option
if prefs.includeGpsExifData == nil then
	prefs.includeGpsExifData = false  -- Disabled by default for privacy
end

-- Hierarchical keyword options
if prefs.useHierarchicalKeywords == nil then
	prefs.useHierarchicalKeywords = true  -- Enable by default
end

if prefs.keywordHierarchySeparator == nil then
	prefs.keywordHierarchySeparator = " > "
end

if prefs.createFullHierarchy == nil then
	prefs.createFullHierarchy = true  -- Create all parent keywords, not just leaf
end

if prefs.maxHierarchyDepth == nil then
	prefs.maxHierarchyDepth = 4  -- Limit depth to prevent excessive nesting
end

-- Gemini model selection
if prefs.geminiModel == nil then
	prefs.geminiModel = "gemini-2.5-flash"  -- Default to fastest/cheapest model
end

-- OpenAI configuration defaults
if prefs.openaiModel == nil then
	prefs.openaiModel = "gpt-4o"  -- Default to GPT-4o for best quality/speed balance
end

if prefs.openaiTimeout == nil then
	prefs.openaiTimeout = 30000  -- 30 seconds timeout for OpenAI requests
end

if prefs.openaiMaxTokens == nil then
	prefs.openaiMaxTokens = 1000  -- Reasonable limit for image analysis responses
end

if prefs.openaiTemperature == nil then
	prefs.openaiTemperature = 0.7  -- Balanced creativity for analysis
end
