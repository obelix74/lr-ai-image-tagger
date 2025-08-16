--[[----------------------------------------------------------------------------

 AI Image Tagger - OpenAI Integration
 Copyright 2025 Anand's Photography
 Updated for Lightroom Classic 2024 and OpenAI GPT-4V API

--------------------------------------------------------------------------------

OpenAIAPI.lua

------------------------------------------------------------------------------]]

local LrHttp = import "LrHttp"
local LrDate = import "LrDate"
local LrStringUtils = import "LrStringUtils"
local LrPrefs = import "LrPrefs"
local LrPasswords = import "LrPasswords"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrFunctionContext = import "LrFunctionContext"
local LrTasks = import "LrTasks"

local JSON = require "JSON"
require "Logger"
local PromptPresets = require "PromptPresets"

--------------------------------------------------------------------------------
-- OpenAI API Integration

OpenAIAPI = { }

local httpContentType = "Content-Type"
local httpAccept = "Accept"
local httpAuthorization = "Authorization"

local mimeTypeJson = "application/json"

local keyApiKey = "OpenAI.ApiKey"

local serviceBaseUri = "https://api.openai.com/v1"
local serviceMaxRetries = 3
local defaultTimeout = 30000 -- 30 seconds in milliseconds

-- Get model from preferences (defaults to gpt-4o)
local function getServiceModel()
	local LrPrefs = import "LrPrefs"
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.openaiModel or "gpt-4o"
end

-- Get max tokens from preferences
local function getMaxTokens()
	local LrPrefs = import "LrPrefs"
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.openaiMaxTokens or 1000
end

-- Get temperature from preferences
local function getTemperature()
	local LrPrefs = import "LrPrefs"
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.openaiTemperature or 0.7
end

-- Get timeout from preferences
local function getTimeout()
	local LrPrefs = import "LrPrefs"
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.openaiTimeout or defaultTimeout
end

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

--------------------------------------------------------------------------------

function OpenAIAPI.getVersions()
	versions = { }

	-- Simple version info for OpenAI API
	versions.openai = {
		version = "OpenAI API v1 (2024)",
	}

	return versions
end

function OpenAIAPI.storeApiKey( apiKey )
	math.randomseed( LrDate.currentTime() )
	local salt = tostring( math.random() * 100000 )
	local prefs = LrPrefs.prefsForPlugin()
	prefs.openaiSalt = salt
	LrPasswords.store( keyApiKey, apiKey, salt )
end

function OpenAIAPI.clearApiKey()
	local prefs = LrPrefs.prefsForPlugin()
	prefs.openaiSalt = nil
	LrPasswords.store( keyApiKey, "" )
end

function OpenAIAPI.getApiKey()
	local prefs = LrPrefs.prefsForPlugin()
	local salt = prefs.openaiSalt
	local apiKey = LrPasswords.retrieve( keyApiKey, salt )
	
	-- Log for debugging
	logger:infof( "OpenAI: getApiKey() - secure storage: %s, salt: %s", 
		apiKey and "has key" or "empty", salt and "present" or "none" )
	
	-- Fallback to preferences if not in secure storage (for immediate use)
	if not apiKey or apiKey == "" then
		apiKey = prefs.openaiApiKey
		logger:infof( "OpenAI: getApiKey() - fallback to prefs: %s", 
			apiKey and "has key" or "empty" )
	end
	
	return apiKey
end

function OpenAIAPI.hasApiKey()
	local apiKey = OpenAIAPI.getApiKey()
	local hasKey = apiKey ~= nil and apiKey ~= ""
	logger:infof( "OpenAI: hasApiKey() - result: %s", hasKey and "true" or "false" )
	return hasKey
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

-- Test connection to OpenAI API
function OpenAIAPI.testConnection()
	logger:infof( "OpenAI: testConnection() called" )
	local apiKey = OpenAIAPI.getApiKey()
	if not apiKey or apiKey == "" then
		logger:errorf( "OpenAI: API key not configured in testConnection" )
		return { status = false, message = "API key not configured" }
	end
	
	logger:infof( "OpenAI: Testing connection with model %s", getServiceModel() )
	
	local reqHeaders = {
		{ field = httpContentType, value = mimeTypeJson },
		{ field = httpAccept, value = mimeTypeJson },
		{ field = httpAuthorization, value = "Bearer " .. apiKey },
	}
	
	-- Test with a simple request to validate API key and model access
	local testReqBody = JSON:encode {
		model = getServiceModel(),
		messages = {
			{
				role = "user",
				content = "Hello! Please respond with 'Connection successful' to test the API."
			}
		},
		max_tokens = 10
	}
	
	local serviceUri = string.format( "%s/chat/completions", serviceBaseUri )
	local resBody, resHeaders = LrHttp.post( serviceUri, testReqBody, reqHeaders, "POST", getTimeout() / 1000 )
	
	if not resBody then
		local errorMsg = "Network request failed: no response received"
		if resHeaders and resHeaders.error then
			errorMsg = string.format( "Network error: %s", resHeaders.error.name or "unknown error" )
		end
		logger:errorf( "OpenAI: %s", errorMsg )
		return { status = false, message = errorMsg }
	end
	
	if resHeaders.status == 401 then
		logger:errorf( "OpenAI: Invalid API key" )
		return { status = false, message = "Invalid API key" }
	elseif resHeaders.status == 403 then
		logger:errorf( "OpenAI: Access denied - check API key permissions" )
		return { status = false, message = "Access denied - check API key permissions" }
	elseif resHeaders.status == 404 then
		logger:errorf( "OpenAI: Model not found: %s", getServiceModel() )
		return { status = false, message = string.format( "Model not found: %s", getServiceModel() ) }
	elseif resHeaders.status == 429 then
		logger:errorf( "OpenAI: Rate limit exceeded" )
		return { status = false, message = "Rate limit exceeded - try again later" }
	elseif resHeaders.status == 200 then
		logger:infof( "OpenAI: Connection test successful" )
		return { status = true, message = "Connection successful" }
	else
		local errorMsg = string.format( "HTTP %d error", resHeaders.status )
		if resBody then
			local resJson = JSON:decode( resBody )
			if resJson and resJson.error and resJson.error.message then
				errorMsg = errorMsg .. ": " .. resJson.error.message
			end
		end
		logger:errorf( "OpenAI: %s", errorMsg )
		return { status = false, message = errorMsg }
	end
end

-- Parse OpenAI response and extract metadata
local function parseOpenAIResponse( responseText )
	-- Ensure responseText is a string
	if type(responseText) == "table" then
		logger:errorf( "OpenAI: parseOpenAIResponse received table instead of string: %s", tostring(responseText) )
		responseText = tostring(responseText) or ""
	end
	
	if not responseText or responseText == "" then
		return {
			title = "",
			caption = "",
			headline = "",
			instructions = "",
			location = "",
			keywords = {}
		}
	end
	
	-- Extract JSON from markdown code blocks if present
	local jsonText = responseText
	
	-- Log the raw response for debugging
	logger:infof( "OpenAI: Raw response: %s", string.sub(responseText, 1, 200) .. (string.len(responseText) > 200 and "..." or "") )
	
	-- Check if response is wrapped in markdown code blocks
	local codeBlockPattern = "```json%s*(.-)%s*```"
	local extractedJson = string.match(responseText, codeBlockPattern)
	if extractedJson then
		logger:infof( "OpenAI: Found JSON in ```json code block, extracting..." )
		jsonText = extractedJson
	else
		-- Try with more flexible patterns
		local genericCodeBlockPattern = "```%s*(.-)%s*```"
		extractedJson = string.match(responseText, genericCodeBlockPattern)
		if extractedJson then
			local trimmed = string.match(extractedJson, "^%s*(.-)%s*$")
			if string.find(trimmed, "^%s*{") and string.find(trimmed, "}%s*$") then
				logger:infof( "OpenAI: Found JSON-like content in generic code block, extracting..." )
				jsonText = extractedJson
			end
		end
	end
	
	-- Clean up the extracted JSON text
	jsonText = string.match(jsonText, "^%s*(.-)%s*$") -- trim whitespace
	
	-- Try to parse as JSON first
	logger:infof( "OpenAI: Attempting to parse JSON: %s", string.sub(jsonText, 1, 200) .. (string.len(jsonText) > 200 and "..." or "") )
	local success, analysisResult = pcall( function() return JSON:decode( jsonText ) end )
	
	if success and analysisResult and type(analysisResult) == "table" then
		logger:infof( "OpenAI: JSON parsing successful" )
		
		-- Parse keywords into array
		local keywordsStr = analysisResult.keywords or ""
		local keywords = {}
		if keywordsStr ~= "" then
			for keyword in string.gmatch(keywordsStr, "([^,]+)") do
				local trimmed = string.match(keyword, "^%s*(.-)%s*$") -- trim whitespace
				if trimmed ~= "" then
					table.insert(keywords, { description = trimmed, selected = true })
				end
			end
		end
		
		return {
			title = analysisResult.title or "",
			caption = analysisResult.caption or "",
			headline = analysisResult.headline or analysisResult.description or "",  -- Support both field names
			instructions = analysisResult.instructions or "",
			location = analysisResult.location or "",
			keywords = keywords
		}
	else
		logger:errorf( "OpenAI: JSON parsing failed, falling back to text parsing" )
		-- Fallback text parsing would go here (similar to OllamaAPI)
		return {
			title = "",
			caption = responseText:sub(1, 100), -- Use first part of response as caption
			headline = "",
			instructions = "",
			location = "",
			keywords = {}
		}
	end
end

function OpenAIAPI.analyze( fileName, photo, photoObject )
	local attempts = 0
	while attempts <= serviceMaxRetries do
		local apiKey = OpenAIAPI.getApiKey()
		if not apiKey or apiKey == "" then
			logger:warnf( "OpenAI: API key missing" )
			return { status = false, message = "API key missing" }
		end

		local reqHeaders = {
			{ field = httpContentType, value = mimeTypeJson },
			{ field = httpAccept, value = mimeTypeJson },
			{ field = httpAuthorization, value = "Bearer " .. apiKey },
		}

		-- Get the base prompt
		local prompt = getAnalysisPrompt()
		
		-- Add metadata if enabled and photo object is provided
		local prefs = LrPrefs.prefsForPlugin()
		if prefs.includeGpsExifData and photoObject then
			local metadata = extractMetadata( photoObject )
			if metadata then
				-- Log what metadata we're sending to OpenAI
				logger:infof( "OpenAI: Including EXIF/GPS metadata in analysis" )
				
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

		-- Validate and encode image data
		if not photo or photo == "" then
			local errorMsg = string.format( "Invalid image data for %s: thumbnail generation failed", fileName or "unknown file" )
			logger:errorf( "OpenAI: %s", errorMsg )
			return { status = false, message = errorMsg }
		end
		
		local base64Image = LrStringUtils.encodeBase64( photo )

		-- Create the request body for OpenAI Chat Completions API
		local reqBody = JSON:encode {
			model = getServiceModel(),
			messages = {
				{
					role = "user",
					content = {
						{
							type = "text",
							text = prompt
						},
						{
							type = "image_url",
							image_url = {
								url = "data:image/jpeg;base64," .. base64Image
							}
						}
					}
				}
			},
			max_tokens = getMaxTokens(),
			temperature = getTemperature()
		}
		
		local serviceUri = string.format( "%s/chat/completions", serviceBaseUri )
		
		-- Make HTTP call
		local resBody, resHeaders = LrHttp.post( serviceUri, reqBody, reqHeaders, "POST", getTimeout() / 1000 )
		
		if not resBody then
			local errorMsg = "Network request failed: no response received"
			if resHeaders and resHeaders.error then
				errorMsg = string.format( "Network error: %s", resHeaders.error.name or "unknown error" )
			end
			logger:errorf( "OpenAI: %s", errorMsg )
			return { status = false, message = errorMsg }
		end
		
		if resHeaders.status == 401 then
			logger:warnf( "OpenAI: authorization failure, invalid API key" )
			return { status = false, message = "Invalid API key" }
		elseif resHeaders.status == 429 then
			-- Rate limit - implement exponential backoff
			local retryAfter = resHeaders["retry-after"] or "60"
			local delay = math.min(tonumber(retryAfter) or 60, 60)
			if attempts < serviceMaxRetries then
				logger:warnf( "OpenAI: rate limit exceeded, retrying in %d seconds", delay )
				LrTasks.sleep( delay )
			else
				return { status = false, message = "Rate limit exceeded" }
			end
		elseif resHeaders.status == 200 then
			local resJson = JSON:decode( resBody )
			if resJson.choices and #resJson.choices > 0 then
				local choice = resJson.choices[1]
				if choice.message and choice.message.content then
					local results = { status = true }
					local analysisResult = parseOpenAIResponse( choice.message.content )
					
					results.title = analysisResult.title
					results.caption = analysisResult.caption
					results.headline = analysisResult.headline
					results.instructions = analysisResult.instructions
					results.copyright = ""
					results.location = analysisResult.location
					results.keywords = analysisResult.keywords
					
					return results
				else
					logger:errorf( "OpenAI: Invalid response structure" )
					return { status = false, message = "Invalid response structure" }
				end
			else
				logger:errorf( "OpenAI: No choices in response" )
				return { status = false, message = "No response choices" }
			end
		else
			local errorMsg = "Unknown error"
			if resJson and resJson.error and resJson.error.message then
				errorMsg = resJson.error.message
			end
			logger:errorf( "OpenAI: analyze API failed: %s", errorMsg )
			return { status = false, message = errorMsg }
		end
		
		attempts = attempts + 1
	end
	
	return { status = false, message = "Maximum retries exceeded" }
end

-- Batch processing with rate limiting
function OpenAIAPI.analyzeBatch( photos, progressCallback )
	local prefs = LrPrefs.prefsForPlugin()
	local batchSize = prefs.batchSize or 5
	local delay = prefs.delayBetweenRequests or 2000 -- More conservative for OpenAI
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
			local result = OpenAIAPI.analyze(photoData.fileName, photoData.jpegData, photoData.photo)
			table.insert(results, result)

			if progressCallback then
				progressCallback(i + j - 1, #photos)
			end

			-- Add delay between requests to respect OpenAI rate limits
			if j < #batch or batchEnd < #photos then
				LrTasks.sleep(delay / 1000) -- Convert milliseconds to seconds
			end
		end
	end

	return results
end

-- Get default prompt for UI display
function OpenAIAPI.getDefaultPrompt()
	return getDefaultPrompt()
end

-- Load prompt from text file
function OpenAIAPI.loadPromptFromFile(filePath)
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
function OpenAIAPI.getPromptPresets()
	return PromptPresets.getPresets()
end

-- Get preset names for UI dropdown
function OpenAIAPI.getPresetNames()
	return PromptPresets.getPresetNames()
end

-- Get a specific preset by name
function OpenAIAPI.getPreset(name)
	return PromptPresets.getPreset(name)
end