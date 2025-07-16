--[[----------------------------------------------------------------------------

 AI Image Tagger
 Copyright 2024 Anand Kumar Sankaran
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

local propSaveTitleToIptc = "saveTitleToIptc"
local propSaveCaptionToIptc = "saveCaptionToIptc"
local propSaveHeadlineToIptc = "saveHeadlineToIptc"
local propSaveInstructionsToIptc = "saveInstructionsToIptc"
local propSaveLocationToIptc = "saveLocationToIptc"

local propUseCustomPrompt = "useCustomPrompt"
local propCustomPrompt = "customPrompt"
local propBatchSize = "batchSize"
local propDelayBetweenRequests = "delayBetweenRequests"
local propIncludeGpsExifData = "includeGpsExifData"
local propResponseLanguage = "responseLanguage"

local propApiKey = "apiKey"
local propVersions = "versions"

-- canned strings
local loadingText = LOC( "$$$/AiTagger/Options/Loading=loading..." )

local titleKeywordAsIs   = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/None=as-is" )
local titleKeywordPrefix = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/Prefix=with Prefix" )
local titleKeywordSuffix = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/Suffix=with Suffix" )
local titleKeywordParent = LOC( "$$$/AiTagger/Options/DecorateKeywords/Title/Parent=under Parent" )

local placeholderKeywordPrefix = LOC( "$$$/AiTagger/Options/DecorateKeywords/PlaceHolder/Prefix=<prefix>" )
local placeholderKeywordSuffix = LOC( "$$$/AiTagger/Options/DecorateKeywords/PlaceHolder/Suffix=<suffix>" )
local placeholderKeywordParent = LOC( "$$$/AiTagger/Options/DecorateKeywords/PlaceHolder/Parent=<parent>" )

--------------------------------------------------------------------------------


local function loadApiKey( propertyTable )
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
	propertyTable[ propVersions ] = {
		gemini = {
			version = loadingText,
		},
	}
	LrTasks.startAsyncTask(
		function()
			propertyTable[ propVersions ] = GeminiAPI.getVersions()
		end
	)

	propertyTable[ propGeneralMaxTasks ] = prefs.maxTasks

	propertyTable[ propDecorateKeyword ] = prefs.decorateKeyword
	propertyTable[ propDecorateKeywordValue ] = prefs.decorateKeywordValue

	propertyTable[ propSaveTitleToIptc ] = prefs.saveTitleToIptc
	propertyTable[ propSaveCaptionToIptc ] = prefs.saveCaptionToIptc
	propertyTable[ propSaveHeadlineToIptc ] = prefs.saveHeadlineToIptc
	propertyTable[ propSaveInstructionsToIptc ] = prefs.saveInstructionsToIptc
	propertyTable[ propSaveLocationToIptc ] = prefs.saveLocationToIptc

	propertyTable[ propUseCustomPrompt ] = prefs.useCustomPrompt
	propertyTable[ propCustomPrompt ] = prefs.customPrompt or ""
	propertyTable[ "selectedPreset" ] = ""
	propertyTable[ propBatchSize ] = prefs.batchSize
	propertyTable[ propDelayBetweenRequests ] = prefs.delayBetweenRequests
	propertyTable[ propIncludeGpsExifData ] = prefs.includeGpsExifData
	propertyTable[ propResponseLanguage ] = prefs.responseLanguage or "English"

	-- Add observer for preset selection
	propertyTable:addObserver( "selectedPreset", function( properties, key, newValue )
		if newValue and newValue ~= "" then
			local preset = GeminiAPI.getPreset(newValue)
			if preset then
				-- Direct property assignment
				propertyTable[propCustomPrompt] = preset.prompt
				-- Force UI refresh
				local currentValue = propertyTable[propUseCustomPrompt]
				propertyTable[propUseCustomPrompt] = not currentValue
				propertyTable[propUseCustomPrompt] = currentValue
				-- Reset dropdown selection
				propertyTable["selectedPreset"] = ""
			else
				logger:errorf("Failed to get preset: %s", newValue)
			end
		end
	end )

	loadApiKey( propertyTable )
end

local function endDialog( propertyTable )
	prefs.maxTasks = propertyTable[ propGeneralMaxTasks ]

	prefs.decorateKeyword = propertyTable[ propDecorateKeyword ]
	prefs.decorateKeywordValue = LrStringUtils.trimWhitespace( propertyTable[ propDecorateKeywordValue ] or "" )

	prefs.saveTitleToIptc = propertyTable[ propSaveTitleToIptc ]
	prefs.saveCaptionToIptc = propertyTable[ propSaveCaptionToIptc ]
	prefs.saveHeadlineToIptc = propertyTable[ propSaveHeadlineToIptc ]
	prefs.saveInstructionsToIptc = propertyTable[ propSaveInstructionsToIptc ]
	prefs.saveLocationToIptc = propertyTable[ propSaveLocationToIptc ]

	prefs.useCustomPrompt = propertyTable[ propUseCustomPrompt ]
	prefs.customPrompt = LrStringUtils.trimWhitespace( propertyTable[ propCustomPrompt ] or "" )
	prefs.batchSize = propertyTable[ propBatchSize ]
	prefs.delayBetweenRequests = propertyTable[ propDelayBetweenRequests ]
	prefs.includeGpsExifData = propertyTable[ propIncludeGpsExifData ]
	prefs.responseLanguage = propertyTable[ propResponseLanguage ]

	storeApiKey( propertyTable )
end

local function sectionsForTopOfDialog( f, propertyTable )

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
					placeholder_string = LOC( "$$$/AiTagger/Options/General/MaxTasksPlaceholder=<max requests>" ),
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
		-- language options
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/Options/Language/Title=AI Response Language" ),
			spacing = f:control_spacing(),
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Language/Prompt=AI Response Language:" ),
					width = share( propGeneralOptionsPromptWidth ),
					alignment = "right",
				},
				f:popup_menu {
					value = bind { key = propResponseLanguage },
					items = {
						{ title = LOC( "$$$/AiTagger/Language/English=English" ), value = "English" },
						{ title = LOC( "$$$/AiTagger/Language/Spanish=Spanish" ), value = "Spanish" },
						{ title = LOC( "$$$/AiTagger/Language/French=French" ), value = "French" },
						{ title = LOC( "$$$/AiTagger/Language/German=German" ), value = "German" },
						{ title = LOC( "$$$/AiTagger/Language/Italian=Italian" ), value = "Italian" },
						{ title = LOC( "$$$/AiTagger/Language/Portuguese=Portuguese" ), value = "Portuguese" },
						{ title = LOC( "$$$/AiTagger/Language/Russian=Russian" ), value = "Russian" },
						{ title = LOC( "$$$/AiTagger/Language/Japanese=Japanese" ), value = "Japanese" },
						{ title = LOC( "$$$/AiTagger/Language/Korean=Korean" ), value = "Korean" },
						{ title = LOC( "$$$/AiTagger/Language/ChineseSimplified=Chinese (Simplified)" ), value = "Chinese" },
						{ title = LOC( "$$$/AiTagger/Language/Dutch=Dutch" ), value = "Dutch" },
						{ title = LOC( "$$$/AiTagger/Language/Polish=Polish" ), value = "Polish" },
						{ title = LOC( "$$$/AiTagger/Language/Turkish=Turkish" ), value = "Turkish" },
						{ title = LOC( "$$$/AiTagger/Language/Arabic=Arabic" ), value = "Arabic" },
						{ title = LOC( "$$$/AiTagger/Language/Hindi=Hindi" ), value = "Hindi" },
						{ title = LOC( "$$$/AiTagger/Language/Tamil=Tamil" ), value = "Tamil" },
					},
				},
			},
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Language/Help=Select the language for AI-generated titles, captions, descriptions, and keywords. This setting applies to all Gemini AI responses." ),
					text_color = LrColor( 0.5, 0.5, 0.5 ),
					width_in_chars = 80,
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
			},
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveTitle=Save title to IPTC metadata" ),
					value = bind { key = propSaveTitleToIptc },
					fill_horizontal = 1,
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
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveHeadline=Save headline to IPTC metadata" ),
					value = bind { key = propSaveHeadlineToIptc },
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
					title = LOC( "$$$/AiTagger/Options/IPTC/SaveLocation=Save location to IPTC metadata" ),
					value = bind { key = propSaveLocationToIptc },
					fill_horizontal = 1,
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
					title = LOC( "$$$/AiTagger/Options/AI/PromptPresets=Preset Prompts:" ),
					width = share( propKeywordOptionsPromptWidth ),
					alignment = "right",
				},
				f:popup_menu {
					enabled = bind { key = propUseCustomPrompt },
					items = (function()
						local items = {{ title = LOC( "$$$/AiTagger/Preset/SelectPreset=Select a preset..." ), value = "" }}
						local presets = GeminiAPI.getPromptPresets()
						for _, preset in ipairs(presets) do
							table.insert(items, { title = preset.name .. " - " .. preset.description, value = preset.name })
						end
						return items
					end)(),
					value = bind { key = "selectedPreset" },
				},
				f:spacer { width = 8 },
				f:push_button {
					enabled = bind { key = propUseCustomPrompt },
					title = LOC( "$$$/AiTagger/Options/AI/BrowseFile=Browse File..." ),
					action = function()
						local fileName = LrDialogs.runOpenPanel({
							title = LOC( "$$$/AiTagger/Prompt/SelectFile=Select Prompt File" ),
							prompt = LOC( "$$$/AiTagger/Prompt/ChooseFile=Choose a text file containing your custom prompt:" ),
							canChooseFiles = true,
							canChooseDirectories = false,
							allowsMultipleSelection = false,
							fileTypes = { "txt", "text" },
							initialDirectory = LrPathUtils.getStandardFilePath( "documents" ),
						})

						if fileName and fileName[1] then
							local content, error = GeminiAPI.loadPromptFromFile(fileName[1])
							if content then
								-- Direct property assignment
								propertyTable[propCustomPrompt] = content
								-- Force UI refresh
								local currentValue = propertyTable[propUseCustomPrompt]
								propertyTable[propUseCustomPrompt] = not currentValue
								propertyTable[propUseCustomPrompt] = currentValue
							else
								logger:errorf("Failed to load file: %s", error or "unknown error")
								LrDialogs.message( LOC( "$$$/AiTagger/Prompt/ErrorLoadingFile=Error Loading File" ), error or LOC( "$$$/AiTagger/Prompt/CouldNotLoadFile=Could not load prompt from file." ), "error" )
							end
						end
					end,
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
					placeholder_string = LOC( "$$$/AiTagger/Options/AI/CustomPromptPlaceholder=Enter your custom prompt here or select a preset above..." ),
					value = bind { key = propCustomPrompt },
					fill_horizontal = 1,
					height_in_lines = 8,
					scrollable = true,
					wrap = true,
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

		-- Privacy options
		{
			bind_to_object = propertyTable,
			title = LOC( "$$$/AiTagger/Options/Privacy/Title=Privacy & Metadata" ),
			spacing = f:control_spacing(),
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = LOC( "$$$/AiTagger/Options/Privacy/IncludeGpsExif=Include GPS location and EXIF metadata in AI analysis" ),
					value = bind { key = propIncludeGpsExifData },
					fill_horizontal = 1,
				},
			},
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = LOC( "$$$/AiTagger/Options/Privacy/IncludeGpsExifHelp=When enabled, camera settings, GPS coordinates, and technical metadata will be shared with Gemini AI to enhance analysis accuracy. Disable for enhanced privacy." ),
					text_color = LrColor( 0.5, 0.5, 0.5 ),
					width_in_chars = 80,
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
						return LOC( "$$$/AiTagger/ApiKey/Configured=API key configured" )
					else
						return LOC( "$$$/AiTagger/ApiKey/NotConfigured=API key not configured" )
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
