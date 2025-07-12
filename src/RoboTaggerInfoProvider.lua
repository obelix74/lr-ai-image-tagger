--[[----------------------------------------------------------------------------

 RoboTagger
 Copyright 2017 Tapani Otala

--------------------------------------------------------------------------------

RoboTaggerInfoProvider.lua

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

local propApiKey = "apiKey"
local propVersions = "versions"

-- canned strings
local loadingText = LOC( "$$$/RoboTagger/Options/Loading=loading..." )
local sampleKeyword = LOC( "$$$/RoboTagger/Options/DecorateKeywords/SampleKeyword=sample keyword" )

local titleKeywordAsIs   = LOC( "$$$/RoboTagger/Options/DecorateKeywords/Title/None=as-is" )
local titleKeywordPrefix = LOC( "$$$/RoboTagger/Options/DecorateKeywords/Title/Prefix=with Prefix" )
local titleKeywordSuffix = LOC( "$$$/RoboTagger/Options/DecorateKeywords/Title/Suffix=with Suffix" )
local titleKeywordParent = LOC( "$$$/RoboTagger/Options/DecorateKeywords/Title/Parent=under Parent" )

local placeholderKeywordPrefix = LOC( "$$$/RoboTagger/Options/DecorateKeywords/PlaceHolder/Prefix=<prefix>" )
local placeholderKeywordSuffix = LOC( "$$$/RoboTagger/Options/DecorateKeywords/PlaceHolder/Suffix=<suffix>" )
local placeholderKeywordParent = LOC( "$$$/RoboTagger/Options/DecorateKeywords/PlaceHolder/Parent=<parent>" )

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
	logger:tracef( "RoboTaggerInfoProvider: startDialog" )

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

	loadApiKey( propertyTable )
end

local function endDialog( propertyTable )
	logger:tracef( "RoboTaggerInfoProvider: endDialog" )

	prefs.maxTasks = propertyTable[ propGeneralMaxTasks ]

	prefs.decorateKeyword = propertyTable[ propDecorateKeyword ]
	prefs.decorateKeywordValue = LrStringUtils.trimWhitespace( propertyTable[ propDecorateKeywordValue ] or "" )

	prefs.saveCaptionToIptc = propertyTable[ propSaveCaptionToIptc ]
	prefs.saveDescriptionToIptc = propertyTable[ propSaveDescriptionToIptc ]

	storeApiKey( propertyTable )
end

local function sectionsForTopOfDialog( f, propertyTable )
	logger:tracef( "RoboTaggerInfoProvider: sectionsForTopOfDialog" )

	return {
		-- general options
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/RoboTagger/Options/General/Title=General Options" ),
			spacing = f:control_spacing(),
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/RoboTagger/Options/General/MaxTasks=Max Parallel Requests:" ),
					width = share( propGeneralOptionsPromptWidth ),
					alignment = "right",
				},
				f:edit_field {
					placeholder_string = LOC( "$$$/RoboTagger/Options/General/MaxTasks=<max requests>" ),
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
			title = LOC( "$$$/RoboTagger/Options/Keywords/Title=Keyword Options" ),
			spacing = f:control_spacing(),

			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/RoboTagger/Options/Keywords/Prompt=Create Keywords:" ),
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
						title = LOC( "$$$/RoboTagger/Options/Keywords/Arrow=^U+25B6" )
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
					title = LOC( "$$$/RoboTagger/Options/IPTC/SaveCaption=Save caption to IPTC metadata" ),
					value = bind { key = propSaveCaptionToIptc },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/RoboTagger/Options/IPTC/SaveDescription=Save description to IPTC metadata" ),
					value = bind { key = propSaveDescriptionToIptc },
					fill_horizontal = 1,
				},
			},
		},

		-- API key
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/RoboTagger/ApiKey/Title=Gemini AI API Key" ),
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
					title = LOC( "$$$/RoboTagger/ApiKey/Key=API Key:" ),
					width = share( propCredentialsPromptWidth ),
					alignment = "right",
				},
				f:password_field {
					placeholder_string = LOC( "$$$/RoboTagger/ApiKey/KeyPlaceHolder=<API key>" ),
					value = bind { key = propApiKey },
					fill_horizontal = 1,
					height_in_lines = 1,
				},
			},
			f:row {
				f:push_button {
					title = LOC( "$$$/RoboTagger/ApiKey/Setup=Get API Key..." ),
					place_horizontal = 1,
					action = function( btn )
						LrHttp.openUrlInBrowser( "https://ai.google.dev/gemini-api/docs/api-key" )
					end,
				},
				f:push_button {
					title = LOC( "$$$/RoboTagger/ApiKey/Clear=Clear" ),
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
			title = LOC( "$$$/RoboTagger/Versions/Title=Versions" ),
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
					title = LOC( "$$$/RoboTagger/Versions/Gemini/Arrow=^U+25B6" )
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
