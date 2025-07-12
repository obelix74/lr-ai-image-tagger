--[[----------------------------------------------------------------------------

 AI Image Tagger
 Copyright 2017-2024 Tapani Otala, Enhanced by Anand Kumar Sankaran
 Updated for Lightroom Classic 2024 and Gemini AI

--------------------------------------------------------------------------------

AiTaggerInfoProvider.lua

------------------------------------------------------------------------------]]

local LrApplication = import "LrApplication"
local LrPrefs = import "LrPrefs"
local LrTasks = import "LrTasks"
local LrHttp = import "LrHttp"
local LrStringUtils = import "LrStringUtils"
local LrPathUtils = import "LrPathUtils"
local LrDialogs = import "LrDialogs"
local LrBinding = import "LrBinding"
local LrColor = import "LrColor"
local LrView = import "LrView"
local bind = LrView.bind
local share = LrView.share

--------------------------------------------------------------------------------

local inspect = require "inspect"
require "Logger"
require "GeminiAPI"

--------------------------------------------------------------------------------

local prefs = LrPrefs.prefsForPlugin()

-- shared properties for aligning prompts
local propGeneralOptionsPromptWidth = "generalOptionsPromptWidth"
local propKeywordOptionsPromptWidth = "keywordOptionsPromptWidth"
local propCredentialsPromptWidth = "credentialsPromptWidth"

-- properties for option controls
local propGeneralMaxTasks = "generalMaxTasks"

local propDecorateKeyword = "decorateKeyword"
local propDecorateKeywordValue = "decorateKeywordValue"

local propSaveCaptionToIptc = "saveCaptionToIptc"
local propSaveDescriptionToIptc = "saveDescriptionToIptc"
local propSaveInstructionsToIptc = "saveInstructionsToIptc"
local propSaveCopyrightToIptc = "saveCopyrightToIptc"
local propSaveLocationToIptc = "saveLocationToIptc"
local propSaveKeywordsToIptc = "saveKeywordsToIptc"

local propUseCustomPrompt = "useCustomPrompt"
local propCustomPrompt = "customPrompt"
local propBatchSize = "batchSize"
local propDelayBetweenRequests = "delayBetweenRequests"

local propApiKey = "apiKey"
local propVersions = "versions"

-- canned strings
local loadingText = LOC( "$$$/AiTagger/Options/Loading=loading..." )
local sampleKeyword = LOC( "$$$/AiTagger/Options/DecorateKeywords/SampleKeyword=sample keyword" )

local titleKeywordAsIs   = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/None=as-is" )
local titleKeywordPrefix = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/Prefix=with Prefix" )
local titleKeywordSuffix = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/Suffix=with Suffix" )
local titleKeywordParent = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/Parent=under Parent" )

local placeholderKeywordPrefix = LOC( "$$$/AiTagger/Options/DecorateKeywords/PlaceHolder/Prefix=<prefix>" )
local placeholderKeywordSuffix = LOC( "$$$/AiTagger/Options/DecorateKeywords/PlaceHolder/Suffix=<suffix>" )
local placeholderKeywordParent = LOC( "$$$/AiTagger/Options/DecorateKeywords/PlaceHolder/Parent=<parent>" )

--------------------------------------------------------------------------------

local function renderSampleKeyword( decoration, value )
	if value then
		value = LrStringUtils.trimWhitespace( value )
		if value == "" then
			value = nil
		end
	end
	if decoration == decorateKeywordPrefix then
		return string.format( "%s %s", value or placeholderKeywordPrefix, sampleKeyword )
	elseif decoration == decorateKeywordSuffix then
		return string.format( "%s %s", sampleKeyword, value or placeholderKeywordSuffix )
	elseif decoration == decorateKeywordParent then
		return string.format( "%s/%s", value or placeholderKeywordParent, sampleKeyword )
	end
	-- decoration == decorateKeywordAsIs
	return sampleKeyword
end

local function loadApiKey( propertyTable )
	logger:tracef( "loading API key from keystore" )
	local apiKey = GeminiAPI.getApiKey()
	if apiKey then
		propertyTable[ propApiKey ] = apiKey
	else
		propertyTable[ propApiKey ] = ""
	end
end

local function storeApiKey( propertyTable )
	local apiKey = propertyTable[ propApiKey ]
	if apiKey and apiKey ~= "" then
		GeminiAPI.storeApiKey( apiKey )
	end
end

local function clearApiKey( propertyTable )
	GeminiAPI.clearApiKey()
	propertyTable[ propApiKey ] = ""
end

local function startDialog( propertyTable )
	logger:tracef( "AiTaggerInfoProvider: startDialog" )

	propertyTable[ propVersions ] = {
		gemini = {
			version = loadingText,
		},
	}
	LrTasks.startAsyncTask(
		function()
			logger:tracef( "getting Gemini API versions" )
			propertyTable[ propVersions ] = GeminiAPI.getVersions()
			logger:tracef( "got Gemini API versions" )
		end
	)

	propertyTable[ propGeneralMaxTasks ] = prefs.maxTasks

	propertyTable[ propDecorateKeyword ] = prefs.decorateKeyword
	propertyTable[ propDecorateKeywordValue ] = prefs.decorateKeywordValue

	propertyTable[ propSaveCaptionToIptc ] = prefs.saveCaptionToIptc
	propertyTable[ propSaveDescriptionToIptc ] = prefs.saveDescriptionToIptc
	propertyTable[ propSaveInstructionsToIptc ] = prefs.saveInstructionsToIptc
	propertyTable[ propSaveCopyrightToIptc ] = prefs.saveCopyrightToIptc
	propertyTable[ propSaveLocationToIptc ] = prefs.saveLocationToIptc
	propertyTable[ propSaveKeywordsToIptc ] = prefs.saveKeywordsToIptc

	propertyTable[ propUseCustomPrompt ] = prefs.useCustomPrompt
	propertyTable[ propCustomPrompt ] = prefs.customPrompt
	propertyTable[ propBatchSize ] = prefs.batchSize
	propertyTable[ propDelayBetweenRequests ] = prefs.delayBetweenRequests

	loadApiKey( propertyTable )
end

local function endDialog( propertyTable )
	logger:tracef( "AiTaggerInfoProvider: endDialog" )

	prefs.maxTasks = propertyTable[ propGeneralMaxTasks ]

	prefs.decorateKeyword = propertyTable[ propDecorateKeyword ]
	prefs.decorateKeywordValue = LrStringUtils.trimWhitespace( propertyTable[ propDecorateKeywordValue ] or "" )

	prefs.saveCaptionToIptc = propertyTable[ propSaveCaptionToIptc ]
	prefs.saveDescriptionToIptc = propertyTable[ propSaveDescriptionToIptc ]
	prefs.saveInstructionsToIptc = propertyTable[ propSaveInstructionsToIptc ]
	prefs.saveCopyrightToIptc = propertyTable[ propSaveCopyrightToIptc ]
	prefs.saveLocationToIptc = propertyTable[ propSaveLocationToIptc ]
	prefs.saveKeywordsToIptc = propertyTable[ propSaveKeywordsToIptc ]

	prefs.useCustomPrompt = propertyTable[ propUseCustomPrompt ]
	prefs.customPrompt = LrStringUtils.trimWhitespace( propertyTable[ propCustomPrompt ] or "" )
	prefs.batchSize = propertyTable[ propBatchSize ]
	prefs.delayBetweenRequests = propertyTable[ propDelayBetweenRequests ]

	storeApiKey( propertyTable )
end

local function sectionsForTopOfDialog( f, propertyTable )
	logger:tracef( "AiTaggerInfoProvider: sectionsForTopOfDialog" )

	return {
		-- general options
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/Options/General/Title=General Options" ),
			spacing = f:control_spacing(),
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/General/MaxTasks=Max Parallel Requests:" ),
					width = share( propGeneralOptionsPromptWidth ),
					alignment = "right",
				},
				f:edit_field {
					placeholder_string = LOC( "$$$/AiTagger/Options/General/MaxTasks=<max requests>" ),
					value = bind { key = propGeneralMaxTasks },
					immediate = true,
					min = tasksMin,
					max = tasksMax,
					increment = tasksStep,
					precision = 0,
					width_in_digits = 4,
				},
				f:static_text {
					title = string.format( "%d", tasksMin ),
					alignment = "right",
				},
				f:slider {
					fill_horizontal = 1,
					value = bind { key = propGeneralMaxTasks },
					min = tasksMin,
					max = tasksMax,
					integral = tasksStep,
				},
				f:static_text {
					title = string.format( "%d", tasksMax ),
					alignment = "left",
				},
			},
		},
		-- keyword options
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/Options/Keywords/Title=Keyword Options" ),
			spacing = f:control_spacing(),

			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Keywords/Prompt=Create Keywords:" ),
					width = share( propKeywordOptionsPromptWidth ),
					alignment = "right",
				},
				f:popup_menu {
					value = bind { key = propDecorateKeyword },
					items = {
						{ title = titleKeywordAsIs,   value = decorateKeywordAsIs   },
						{ title = titleKeywordPrefix, value = decorateKeywordPrefix },
						{ title = titleKeywordSuffix, value = decorateKeywordSuffix },
						{ title = titleKeywordParent, value = decorateKeywordParent },
					},
				},
				f:row {
					place = "overlapping",
					fill_horizontal = 0.5,
					f:edit_field {
						visible = LrBinding.keyEquals( propDecorateKeyword, decorateKeywordPrefix ),
						placeholder_string = placeholderKeywordPrefix,
						value = bind { key = propDecorateKeywordValue },
						immediate = true,
						width_in_chars = 10,
					},
					f:edit_field {
						visible = LrBinding.keyEquals( propDecorateKeyword, decorateKeywordSuffix ),
						placeholder_string = placeholderKeywordSuffix,
						value = bind { key = propDecorateKeywordValue },
						immediate = true,
						width_in_chars = 10,
					},
					f:edit_field {
						visible = LrBinding.keyEquals( propDecorateKeyword, decorateKeywordParent ),
						placeholder_string = placeholderKeywordParent,
						value = bind { key = propDecorateKeywordValue },
						immediate = true,
						width_in_chars = 10,
					},
				},
				f:row {
					fill_horizontal = 1,
					f:static_text {
						title = LOC( "$$$/AiTagger/Options/Keywords/Arrow=^U+25B6" )
					},
					f:static_text {
						title = bind {
							keys = { propDecorateKeyword, propDecorateKeywordValue },
							operation = function( binder, values, fromTable )
								return renderSampleKeyword(
									values[ propDecorateKeyword ],
									values[ propDecorateKeywordValue ] )
							end,
						},
						font = "Courier",
						text_color = LrColor( 0, 0, 1 ),
					},
				},
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveCaption=Save caption to IPTC metadata" ),
					value = bind { key = propSaveCaptionToIptc },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveDescription=Save description to IPTC metadata" ),
					value = bind { key = propSaveDescriptionToIptc },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveInstructions=Save instructions to IPTC metadata" ),
					value = bind { key = propSaveInstructionsToIptc },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveCopyright=Save copyright to IPTC metadata" ),
					value = bind { key = propSaveCopyrightToIptc },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveLocation=Save location to IPTC metadata" ),
					value = bind { key = propSaveLocationToIptc },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveKeywords=Save keywords to IPTC metadata (Note: Keywords auto-included in IPTC on export)" ),
					value = bind { key = propSaveKeywordsToIptc },
					fill_horizontal = 1,
					enabled = false,  -- Disabled due to Lightroom SDK limitations
				},
			},
		},

		-- AI prompt customization
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/Options/AI/Title=AI Prompt Customization" ),
			spacing = f:control_spacing(),
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/AI/UseCustomPrompt=Use custom prompt" ),
					value = bind { key = propUseCustomPrompt },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/AI/CustomPrompt=Custom Prompt:" ),
					width = share( propKeywordOptionsPromptWidth ),
					alignment = "right",
				},
				f:edit_field {
					enabled = bind { key = propUseCustomPrompt },
					placeholder_string = bind {
						key = propUseCustomPrompt,
						transform = function( value, fromTable )
							if not value then
								return GeminiAPI.getDefaultPrompt()
							else
								return LOC( "$$$/AiTagger/Options/AI/CustomPromptPlaceholder=Enter your custom prompt here..." )
							end
						end,
					},
					value = bind { key = propCustomPrompt },
					fill_horizontal = 1,
					height_in_lines = 6,
				},
			},
		},

		-- batch processing options
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/Options/Batch/Title=Batch Processing" ),
			spacing = f:control_spacing(),
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Batch/BatchSize=Batch Size:" ),
					width = share( propKeywordOptionsPromptWidth ),
					alignment = "right",
				},
				f:edit_field {
					value = bind { key = propBatchSize },
					immediate = true,
					min = 1,
					max = 10,
					increment = 1,
					precision = 0,
					width_in_digits = 2,
				},
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Batch/BatchSizeHelp=(1-10 photos per batch)" ),
				},
			},
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Batch/Delay=Delay Between Requests:" ),
					width = share( propKeywordOptionsPromptWidth ),
					alignment = "right",
				},
				f:edit_field {
					value = bind { key = propDelayBetweenRequests },
					immediate = true,
					min = 500,
					max = 5000,
					increment = 100,
					precision = 0,
					width_in_digits = 4,
				},
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Batch/DelayHelp=milliseconds (500-5000)" ),
				},
			},
		},

		-- API key
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/ApiKey/Title=Gemini AI API Key" ),
			synopsis = bind {
				key = propApiKey,
				object = propertyTable,
				transform = function( value, fromTable )
					if value and value ~= "" then
						return "API key configured"
					else
						return "API key not configured"
					end
				end,
			},
			spacing = f:control_spacing(),
			f:row {
				f:static_text {
					title = LOC( "$$$/AiTagger/ApiKey/Key=API Key:" ),
					width = share( propCredentialsPromptWidth ),
					alignment = "right",
				},
				f:password_field {
					placeholder_string = LOC( "$$$/AiTagger/ApiKey/KeyPlaceHolder=<API key>" ),
					value = bind { key = propApiKey },
					fill_horizontal = 1,
					height_in_lines = 1,
				},
			},
			f:row {
				f:push_button {
					title = LOC( "$$$/AiTagger/ApiKey/Setup=Get API Key..." ),
					place_horizontal = 1,
					action = function( btn )
						LrHttp.openUrlInBrowser( "https://ai.google.dev/gemini-api/docs/api-key" )
					end,
				},
				f:push_button {
					title = LOC( "$$$/AiTagger/ApiKey/Clear=Clear" ),
					place_horizontal = 1,
					action = function( btn )
						clearApiKey( propertyTable )
					end,
				},
			},
		},
		-- versions
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/Versions/Title=Versions" ),
			synopsis = bind {
				key = propVersions,
				object = propertyTable,
				transform = function( value, fromTable )
					return value.gemini.version
				end,
			},
			spacing = f:label_spacing(),
			f:row {
				f:static_text {
					title = LOC( "$$$/AiTagger/Versions/Gemini/Arrow=^U+25B6" )
				},
				f:static_text {
					title = bind {
						key = propVersions,
						transform = function( value, fromTable )
							return value.gemini.version
						end,
					},
					fill_horizontal = 1,
				},
			},
		},
	}

end

--------------------------------------------------------------------------------

return {

	startDialog = startDialog,
	endDialog = endDialog,

	sectionsForTopOfDialog = sectionsForTopOfDialog,

}
