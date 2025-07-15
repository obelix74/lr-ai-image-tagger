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

logger:tracef( "AI Image Tagger v2.1.0: init for Lightroom Classic 2024 with Gemini AI" )

local prefs = LrPrefs.prefsForPlugin()

decorateKeywordAsIs   = "keywordAsIs"
decorateKeywordPrefix = "keywordPrefix"
decorateKeywordSuffix = "keywordSuffix"
decorateKeywordParent = "keywordParent"

thresholdMin = 0
thresholdMax = 100
thresholdStep = 1

tasksMin = 1
logger:tracef( "system has %d CPUs", LrSystemInfo.numCPUs() )
tasksMax = LrSystemInfo.numCPUs()
tasksStep = 1

if prefs.maxTasks == nil then
	prefs.maxTasks = math.min(tasksMax, 4) -- Limit to 4 concurrent requests for better stability
end

prefs.maxKeywords = 10
-- Increase thumbnail size for better accuracy with modern AI
prefs.thumbnailWidth = 1600
prefs.thumbnailHeight = 1600

if prefs.decorateKeyword == nil then
	prefs.decorateKeyword = decorateKeywordAsIs
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
