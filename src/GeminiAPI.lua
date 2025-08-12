--[[----------------------------------------------------------------------------

 AI Image Tagger
 Copyright 2025 Anand's Photography
 Updated for Lightroom Classic 2024 and Gemini AI API

--------------------------------------------------------------------------------

GeminiAPI.lua

------------------------------------------------------------------------------]]

local LrHttp = import "LrHttp"
local LrDate = import "LrDate"
local LrStringUtils = import "LrStringUtils"
local LrPrefs = import "LrPrefs"
local LrPasswords = import "LrPasswords"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrFunctionContext = import "LrFunctionContext"

local JSON = require "JSON"
require "Logger"
local PromptPresets = require "PromptPresets"

--------------------------------------------------------------------------------
-- Gemini AI API

GeminiAPI = { }

local httpContentType = "Content-Type"
local httpAccept = "Accept"

local mimeTypeJson = "application/json"

local keyApiKey = "GeminiAI.ApiKey"

local serviceBaseUri = "https://generativelanguage.googleapis.com/v1beta"
-- Get model from preferences (defaults to flash in AiTaggerInit.lua)
local function getServiceModel()
	local LrPrefs = import "LrPrefs"
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.geminiModel or "gemini-1.5-flash"
end
local serviceMaxRetries = 2

local tempPath = LrPathUtils.getStandardFilePath( "temp" )
local tempBaseName = "aiimagetagger.tmp"

--------------------------------------------------------------------------------


-- Extract GPS and EXIF metadata from a photo for AI analysis
local function extractMetadata( photo )
	local metadata = {}
	
	-- GPS coordinates (if available)
	local gps = photo:getFormattedMetadata( "gps" )
	if gps and gps ~= "" then
		metadata.gps = gps
	end
	
	-- Copyright information
	local copyright = photo:getFormattedMetadata( "copyright" )
	if copyright and copyright ~= "" then
		metadata.copyright = copyright
	end
	
	-- Location/city information
	local city = photo:getFormattedMetadata( "city" )
	local stateProvince = photo:getFormattedMetadata( "stateProvince" )
	local country = photo:getFormattedMetadata( "country" )
	local location = photo:getFormattedMetadata( "location" )
	if city or stateProvince or country or location then
		metadata.location = {
			city = city,
			stateProvince = stateProvince,
			country = country,
			location = location
		}
	end
	
	-- Camera and lens information
	local cameraMake = photo:getFormattedMetadata( "cameraMake" )
	local cameraModel = photo:getFormattedMetadata( "cameraModel" )
	local lens = photo:getFormattedMetadata( "lens" )
	if cameraMake or cameraModel or lens then
		metadata.camera = {
			make = cameraMake,
			model = cameraModel,
			lens = lens
		}
	end
	
	-- Shooting settings
	local focalLength = photo:getFormattedMetadata( "focalLength" )
	local aperture = photo:getFormattedMetadata( "aperture" )
	local shutterSpeed = photo:getFormattedMetadata( "shutterSpeed" )
	local isoSpeedRating = photo:getFormattedMetadata( "isoSpeedRating" )
	local flash = photo:getFormattedMetadata( "flash" )
	if focalLength or aperture or shutterSpeed or isoSpeedRating or flash then
		metadata.settings = {
			focalLength = focalLength,
			aperture = aperture,
			shutterSpeed = shutterSpeed,
			iso = isoSpeedRating,
			flash = flash
		}
	end
	
	-- Date and time
	local dateTimeOriginal = photo:getFormattedMetadata( "dateTimeOriginal" )
	if dateTimeOriginal then
		metadata.datetime = dateTimeOriginal
	end
	
	-- Image dimensions
	local dimensions = photo:getFormattedMetadata( "dimensions" )
	local croppedDimensions = photo:getFormattedMetadata( "croppedDimensions" )
	if dimensions or croppedDimensions then
		metadata.image = {
			dimensions = dimensions,
			croppedDimensions = croppedDimensions
		}
	end
	
	-- Return nil if no metadata was found
	if next(metadata) == nil then
		return nil
	end
	
	return metadata
end

local function createTempFile( baseName, contents )
	local fileName = LrFileUtils.chooseUniqueFileName( LrPathUtils.child( tempPath, baseName ) )
	local file = io.open( fileName, "w" )
	if file then
		file:write( contents )
		file:close()
		return fileName
	end
	return nil
end

--------------------------------------------------------------------------------

function GeminiAPI.getVersions()
	versions = { }

	-- Simple version info for Gemini API
	versions.gemini = {
		version = "Gemini AI API v1beta (2024)",
	}

	return versions
end

function GeminiAPI.storeApiKey( apiKey )
	math.randomseed( LrDate.currentTime() )
	local salt = tostring( math.random() * 100000 )
	local prefs = LrPrefs.prefsForPlugin()
	prefs.salt = salt
	LrPasswords.store( keyApiKey, apiKey, salt )
end

function GeminiAPI.clearApiKey()
	local prefs = LrPrefs.prefsForPlugin()
	prefs.salt = nil
	LrPasswords.store( keyApiKey, "" )
end

function GeminiAPI.getApiKey()
	local prefs = LrPrefs.prefsForPlugin()
	local salt = prefs.salt
	return LrPasswords.retrieve( keyApiKey, salt )
end

function GeminiAPI.hasApiKey()
	local apiKey = GeminiAPI.getApiKey()
	return apiKey ~= nil and apiKey ~= ""
end

--------------------------------------------------------------------------------

local function getDefaultPrompt()
	local prefs = LrPrefs.prefsForPlugin()
	local language = prefs.responseLanguage or "English"
	local languageInstruction = ""
	
	if language ~= "English" then
		languageInstruction = string.format("IMPORTANT: Please respond in %s language. All text fields (title, caption, headline, keywords, instructions, location) should be in %s.\n\n", language, language)
	end
	
	-- Determine keyword format based on hierarchical setting
	local keywordInstruction = ""
	local keywordExample = ""
	
	if prefs.useHierarchicalKeywords then
		keywordInstruction = "4. A list of relevant hierarchical keywords organized from broad to specific categories using ' > ' separator (e.g., Nature > Wildlife > Birds, Sports > Team Sports > Football)"
		keywordExample = "\"Nature > Wildlife > Birds, Sports > Team Sports > Football, Photography > Wildlife Photography > Telephoto\""
	else
		keywordInstruction = "4. A list of relevant keywords (comma-separated)"
		keywordExample = "\"keyword1, keyword2, keyword3\""
	end
	
	local basePrompt = "Please analyze this photograph and provide:\n1. A short title (2-5 words)\n2. A brief caption (1-2 sentences)\n3. A detailed headline/description (2-3 sentences)\n" .. keywordInstruction .. "\n5. Special instructions for photo editing or usage (if applicable)\n6. Location information (if identifiable landmarks are present)\n\nPlease format your response as JSON with the following structure:\n{\n  \"title\": \"short descriptive title\",\n  \"caption\": \"brief caption here\",\n  \"headline\": \"detailed headline/description here\",\n  \"keywords\": " .. keywordExample .. ",\n  \"instructions\": \"editing suggestions or usage notes\",\n  \"location\": \"location name if identifiable landmarks present\"\n}"
	
	-- Add hierarchical keyword explanation if enabled
	if prefs.useHierarchicalKeywords then
		local hierarchicalInstruction = "\n\nFor hierarchical keywords:\n- Start with broad categories (Nature, Sports, Architecture, Photography)\n- Progress to specific subcategories (Wildlife, Team Sports, Modern Architecture)\n- End with detailed descriptors (Birds, Football, Glass Building)\n- Use ' > ' to separate hierarchy levels\n- Provide 8-12 hierarchical keywords total\n- Examples: \"Nature > Wildlife > Birds > Eagles\", \"Sports > Team Sports > Football\", \"Photography > Portrait Photography > Studio\""
		basePrompt = basePrompt .. hierarchicalInstruction
	end
	
	return languageInstruction .. basePrompt
end

local function getAnalysisPrompt()
	local prefs = LrPrefs.prefsForPlugin()
	local language = prefs.responseLanguage or "English"
	local languageInstruction = ""
	
	if language ~= "English" then
		languageInstruction = string.format("IMPORTANT: Please respond in %s language. All text fields should be in %s.\n\n", language, language)
	end
	
	if prefs.useCustomPrompt and prefs.customPrompt and prefs.customPrompt ~= "" then
		return languageInstruction .. prefs.customPrompt
	else
		return getDefaultPrompt()
	end
end

function GeminiAPI.analyze( fileName, photo, photoObject )
	local attempts = 0
	while attempts <= serviceMaxRetries do
		local apiKey = GeminiAPI.getApiKey()
		if apiKey and apiKey ~= "" then
			local reqHeaders = {
				{ field = httpContentType, value = mimeTypeJson },
				{ field = httpAccept, value = mimeTypeJson },
			}

			-- Get the base prompt
			local prompt = getAnalysisPrompt()
			
			-- Add metadata if enabled and photo object is provided
			local prefs = LrPrefs.prefsForPlugin()
			if prefs.includeGpsExifData and photoObject then
				local metadata = extractMetadata( photoObject )
				if metadata then
					-- Log what metadata we're sending to Gemini
					logger:infof( "GeminiAPI: Including EXIF/GPS metadata in analysis:" )
					logger:infof( "  GPS: %s", metadata.gps or "none" )
					if metadata.settings then
						local settings = {}
						if metadata.settings.focalLength then table.insert( settings, metadata.settings.focalLength ) end
						if metadata.settings.aperture then table.insert( settings, metadata.settings.aperture ) end
						if metadata.settings.shutterSpeed then table.insert( settings, metadata.settings.shutterSpeed ) end
						if metadata.settings.iso then table.insert( settings, "ISO " .. metadata.settings.iso ) end
						if metadata.settings.flash then table.insert( settings, "Flash: " .. metadata.settings.flash ) end
					else
						logger:infof( "  Settings: none" )
					end
					if metadata.location then
						local locationParts = {}
						if metadata.location.city then table.insert(locationParts, metadata.location.city) end
						if metadata.location.stateProvince then table.insert(locationParts, metadata.location.stateProvince) end
						if metadata.location.country then table.insert(locationParts, metadata.location.country) end
						if metadata.location.location then table.insert(locationParts, metadata.location.location) end
						logger:infof( "  Location: %s", #locationParts > 0 and table.concat(locationParts, ", ") or "none" )
					else
						logger:infof( "  Location: none" )
					end
					
					prompt = prompt .. "\n\nAdditional context from photo metadata:\n"
					
					if metadata.gps then
						prompt = prompt .. "GPS Location: " .. metadata.gps .. "\n"
					end
					
					if metadata.camera then
						prompt = prompt .. string.format( "Camera: %s %s", metadata.camera.make or "", metadata.camera.model or "" )
						if metadata.camera.lens then
							prompt = prompt .. string.format( " with %s", metadata.camera.lens )
						end
						prompt = prompt .. "\n"
					end
					
					if metadata.settings then
						local settings = {}
						if metadata.settings.focalLength then table.insert( settings, metadata.settings.focalLength ) end
						if metadata.settings.aperture then table.insert( settings, metadata.settings.aperture ) end
						if metadata.settings.shutterSpeed then table.insert( settings, metadata.settings.shutterSpeed ) end
						if metadata.settings.iso then table.insert( settings, "ISO " .. metadata.settings.iso ) end
						if metadata.settings.flash then table.insert( settings, "Flash: " .. metadata.settings.flash ) end
						if #settings > 0 then
							prompt = prompt .. "Camera settings: " .. table.concat( settings, ", " ) .. "\n"
						end
					end
					
					if metadata.datetime then
						prompt = prompt .. "Captured: " .. metadata.datetime .. "\n"
					end
					
					if metadata.image then
						if metadata.image.dimensions then
							prompt = prompt .. "Image size: " .. metadata.image.dimensions .. "\n"
						end
						if metadata.image.croppedDimensions then
							prompt = prompt .. "Cropped size: " .. metadata.image.croppedDimensions .. "\n"
						end
					end
					
					if metadata.copyright then
						prompt = prompt .. "Copyright: " .. metadata.copyright .. "\n"
					end
					
					if metadata.location then
						local locationParts = {}
						if metadata.location.city then table.insert(locationParts, metadata.location.city) end
						if metadata.location.stateProvince then table.insert(locationParts, metadata.location.stateProvince) end
						if metadata.location.country then table.insert(locationParts, metadata.location.country) end
						if metadata.location.location then table.insert(locationParts, metadata.location.location) end
						if #locationParts > 0 then
							prompt = prompt .. "Location metadata: " .. table.concat(locationParts, ", ") .. "\n"
						end
					end
					
					prompt = prompt .. "\nPlease consider this technical and location information in your analysis and include relevant location details in your response."
				end
			end

			-- Create the request body for Gemini API
			local reqBody = JSON:encode {
				contents = {
					{
						parts = {
							{
								text = prompt
							},
							{
								inline_data = {
									mime_type = "image/jpeg",
									data = LrStringUtils.encodeBase64( photo )
								}
							}
						}
					}
				},
				generationConfig = {
					responseMimeType = "application/json",
					temperature = 0.4,
					topP = 0.8,
					maxOutputTokens = 1024
				}
			}
			
			local serviceUri = string.format( "%s/models/%s:generateContent?key=%s", serviceBaseUri, getServiceModel(), apiKey )
			
			-- Make HTTP call - yielding is now allowed in proper task context
			local resBody, resHeaders = LrHttp.post( serviceUri, reqBody, reqHeaders )
			
			if not resBody then
				local errorMsg = "Network request failed: no response received"
				if resHeaders and resHeaders.error then
					errorMsg = string.format( "Network error: %s", resHeaders.error.name or "unknown error" )
				end
				logger:errorf( "GeminiAPI: %s", errorMsg )
				return { status = false, message = errorMsg }
			end
			
			if resBody then
				local resJson = JSON:decode( resBody )
				if resHeaders.status == 401 then
					logger:warnf( "GeminiAPI: authorization failure, invalid API key" )
					return { status = false, message = "Invalid API key" }
				elseif resHeaders.status == 200 then
					local results = { status = true }
					
					-- Parse the response
					if resJson.candidates and #resJson.candidates > 0 then
						local candidate = resJson.candidates[1]
						if candidate.content and candidate.content.parts and #candidate.content.parts > 0 then
							local responseText = candidate.content.parts[1].text
							local analysisResult = JSON:decode( responseText )

							if analysisResult then
								results.title = analysisResult.title or ""
								results.caption = analysisResult.caption or ""
								results.headline = analysisResult.headline or analysisResult.description or ""  -- Support both new and old field names
								results.instructions = analysisResult.instructions or ""
								results.copyright = ""
								results.location = analysisResult.location or ""

								-- Parse keywords into array
								local keywordsStr = analysisResult.keywords or ""
								results.keywords = {}
								if keywordsStr ~= "" then
									for keyword in string.gmatch(keywordsStr, "([^,]+)") do
										local trimmed = string.match(keyword, "^%s*(.-)%s*$") -- trim whitespace
										if trimmed ~= "" then
											table.insert(results.keywords, { description = trimmed, selected = true })
										end
									end
								end
							else
								results.title = ""
								results.caption = ""
								results.headline = ""
								results.instructions = ""
								results.copyright = ""
								results.location = ""
								results.keywords = {}
							end
						else
							results.title = ""
							results.caption = ""
							results.headline = ""
							results.instructions = ""
							results.copyright = ""
							results.location = ""
							results.keywords = {}
						end
					else
						results.title = ""
						results.caption = ""
						results.headline = ""
						results.instructions = ""
						results.copyright = ""
						results.location = ""
						results.keywords = {}
					end
					
					return results
				else
					local errorMsg = "Unknown error"
					if resJson and resJson.error and resJson.error.message then
						errorMsg = resJson.error.message
					end
					logger:errorf( "GeminiAPI: analyze API failed: %s", errorMsg )
					return { status = false, message = errorMsg }
				end
			else
				logger:errorf( "GeminiAPI: network error: %s(%d): %s", resHeaders.error.errorCode, resHeaders.error.nativeCode, resHeaders.error.name )
				return { status = false, message = resHeaders.error.name }
			end
		else
			logger:warnf( "GeminiAPI: API key missing" )
			return { status = false, message = "API key missing" }
		end
		
		attempts = attempts + 1
	end
	
	return { status = false, message = "Maximum retries exceeded" }
end

-- Batch processing with rate limiting
function GeminiAPI.analyzeBatch( photos, progressCallback )
	local prefs = LrPrefs.prefsForPlugin()
	local batchSize = prefs.batchSize or 5
	local delay = prefs.delayBetweenRequests or 1000
	local results = {}

	for i = 1, #photos, batchSize do
		local batch = {}
		local batchEnd = math.min(i + batchSize - 1, #photos)

		-- Process batch
		for j = i, batchEnd do
			table.insert(batch, photos[j])
		end

		-- Analyze each photo in the batch
		for j, photoData in ipairs(batch) do
			local result = GeminiAPI.analyze(photoData.fileName, photoData.jpegData, photoData.photo)
			table.insert(results, result)

			if progressCallback then
				progressCallback(i + j - 1, #photos)
			end

			-- Add delay between requests to avoid rate limiting
			if j < #batch or batchEnd < #photos then
				LrTasks.sleep(delay / 1000) -- Convert milliseconds to seconds
			end
		end
	end

	return results
end

-- Get default prompt for UI display
function GeminiAPI.getDefaultPrompt()
	return getDefaultPrompt()
end

-- Load prompt from text file
function GeminiAPI.loadPromptFromFile(filePath)
	if not filePath or filePath == "" then
		return nil, "No file path provided"
	end

	-- Protect file operations with error handling
	local success, file = pcall(io.open, filePath, "r")
	if not success or not file then
		return nil, "Could not open file: " .. tostring(file or filePath)
	end

	local readSuccess, content = pcall(function() return file:read("*all") end)
	file:close()
	
	if not readSuccess then
		return nil, "Could not read content from file: " .. tostring(content)
	end

	if not content or content == "" then
		return nil, "File is empty or could not read content"
	end

	-- Trim whitespace
	content = LrStringUtils.trimWhitespace(content)

	return content, nil
end

-- Get available prompt presets
function GeminiAPI.getPromptPresets()
	return PromptPresets.getPresets()
end

-- Get preset names for UI dropdown
function GeminiAPI.getPresetNames()
	return PromptPresets.getPresetNames()
end

-- Get a specific preset by name
function GeminiAPI.getPreset(name)
	return PromptPresets.getPreset(name)
end
