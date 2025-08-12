--[[----------------------------------------------------------------------------

 AI Image Tagger - Ollama Integration
 Copyright 2025 Anand's Photography
 Updated for Lightroom Classic 2024 and Ollama AI API

--------------------------------------------------------------------------------

OllamaAPI.lua

------------------------------------------------------------------------------]]

local LrHttp = import "LrHttp"
local LrDate = import "LrDate"
local LrStringUtils = import "LrStringUtils"
local LrPrefs = import "LrPrefs"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrTasks = import "LrTasks"

local JSON = require "JSON"
require "Logger"
local PromptPresets = require "PromptPresets"

--------------------------------------------------------------------------------
-- Ollama AI API

OllamaAPI = { }

local httpContentType = "Content-Type"
local httpAccept = "Accept"

local mimeTypeJson = "application/json"

local serviceMaxRetries = 2
local defaultTimeout = 300000 -- 5 minutes in milliseconds

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

function OllamaAPI.getVersions()
	versions = { }

	-- Simple version info for Ollama API
	versions.ollama = {
		version = "Ollama AI API (2024)",
	}

	return versions
end

function OllamaAPI.getBaseUrl()
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.ollamaBaseUrl or "http://localhost:11434"
end

function OllamaAPI.setBaseUrl( baseUrl )
	local prefs = LrPrefs.prefsForPlugin()
	prefs.ollamaBaseUrl = baseUrl
end

function OllamaAPI.getModel()
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.ollamaModel or "llava:latest"
end

function OllamaAPI.setModel( model )
	local prefs = LrPrefs.prefsForPlugin()
	prefs.ollamaModel = model
end

function OllamaAPI.getTimeout()
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.ollamaTimeout or defaultTimeout
end

function OllamaAPI.setTimeout( timeout )
	local prefs = LrPrefs.prefsForPlugin()
	prefs.ollamaTimeout = timeout
end

-- Test connection to Ollama server
function OllamaAPI.testConnection()
	local baseUrl = OllamaAPI.getBaseUrl()
	local model = OllamaAPI.getModel()
	
	logger:infof( "OllamaAPI: Testing connection to %s with model %s", baseUrl, model )
	
	local reqHeaders = {
		{ field = httpContentType, value = mimeTypeJson },
		{ field = httpAccept, value = mimeTypeJson },
	}
	
	-- First, check if Ollama is running by getting available models
	local serviceUri = string.format( "%s/api/tags", baseUrl )
	local resBody, resHeaders = LrHttp.get( serviceUri, reqHeaders )
	
	if not resBody or resHeaders.status ~= 200 then
		local errorMsg = "Ollama server not accessible"
		if resHeaders and resHeaders.error then
			errorMsg = string.format( "Connection error: %s", resHeaders.error.name or "unknown error" )
		elseif resHeaders and resHeaders.status then
			errorMsg = string.format( "HTTP %d: Server not accessible", resHeaders.status )
		end
		logger:errorf( "OllamaAPI: %s", errorMsg )
		return { status = false, message = errorMsg }
	end
	
	-- Parse the response to check if our model is available
	local resJson = JSON:decode( resBody )
	if not resJson or not resJson.models then
		logger:errorf( "OllamaAPI: Invalid response from server" )
		return { status = false, message = "Invalid response from Ollama server" }
	end
	
	-- Check if our model is available
	local modelExists = false
	local availableModels = {}
	
	for _, modelInfo in ipairs( resJson.models ) do
		table.insert( availableModels, modelInfo.name )
		if modelInfo.name == model or string.find( modelInfo.name, string.gsub(model, ":latest", "") ) then
			modelExists = true
		end
	end
	
	if not modelExists then
		local errorMsg = string.format( "Model '%s' not found. Available models: %s", model, table.concat( availableModels, ", " ) )
		logger:errorf( "OllamaAPI: %s", errorMsg )
		return { status = false, message = errorMsg }
	end
	
	logger:infof( "OllamaAPI: Connection test successful - model %s is available", model )
	return { status = true, message = "Connection successful" }
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
	local keywordFormatNote = ""
	
	if prefs.useHierarchicalKeywords then
		keywordInstruction = "4. A list of relevant hierarchical keywords organized from broad to specific categories using ' > ' separator (e.g., Nature > Wildlife > Birds, Sports > Team Sports > Football)"
		keywordExample = "\"Nature > Wildlife > Birds, Sports > Team Sports > Football, Photography > Wildlife Photography > Telephoto\""
		keywordFormatNote = "IMPORTANT: The keywords field must be a comma-separated string with hierarchical keywords using ' > ' separators, not an array."
	else
		keywordInstruction = "4. A list of relevant keywords (comma-separated string)"
		keywordExample = "\"keyword1, keyword2, keyword3\""
		keywordFormatNote = "IMPORTANT: The keywords field must be a comma-separated string, not an array."
	end
	
	local basePrompt = "Please analyze this photograph and provide:\n1. A short title (2-5 words)\n2. A brief caption (1-2 sentences)\n3. A detailed headline/description (2-3 sentences)\n" .. keywordInstruction .. "\n5. Special instructions for photo editing or usage (if applicable)\n6. Location information (if identifiable landmarks are present)\n\nPlease format your response as JSON with the following structure:\n{\n  \"title\": \"short descriptive title\",\n  \"caption\": \"brief caption here\",\n  \"headline\": \"detailed headline/description here\",\n  \"keywords\": " .. keywordExample .. ",\n  \"instructions\": \"editing suggestions or usage notes\",\n  \"location\": \"location name if identifiable landmarks present\"\n}\n\n" .. keywordFormatNote
	
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

-- Parse Ollama response (handles both JSON and text responses)
local function parseResponse( responseText )
	-- Ensure responseText is a string
	if type(responseText) == "table" then
		logger:errorf( "OllamaAPI: parseResponse received table instead of string: %s", tostring(responseText) )
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
	logger:infof( "OllamaAPI: Raw response: %s", string.sub(responseText, 1, 200) .. (string.len(responseText) > 200 and "..." or "") )
	
	-- Check if response is wrapped in markdown code blocks - try multiple patterns
	local codeBlockPattern = "```json%s*(.-)%s*```"
	local extractedJson = string.match(responseText, codeBlockPattern)
	if extractedJson then
		logger:infof( "OllamaAPI: Found JSON in ```json code block, extracting..." )
		jsonText = extractedJson
	else
		-- Try with newlines and more flexible matching
		codeBlockPattern = "```json\n(.-)```"
		extractedJson = string.match(responseText, codeBlockPattern)
		if extractedJson then
			logger:infof( "OllamaAPI: Found JSON in ```json\\n code block, extracting..." )
			jsonText = extractedJson
		else
			-- Also try without the 'json' language specifier
			local genericCodeBlockPattern = "```%s*(.-)%s*```"
			extractedJson = string.match(responseText, genericCodeBlockPattern)
			if extractedJson then
				-- Check if the extracted content looks like JSON
				local trimmed = string.match(extractedJson, "^%s*(.-)%s*$")
				if string.find(trimmed, "^%s*{") and string.find(trimmed, "}%s*$") then
					logger:infof( "OllamaAPI: Found JSON-like content in generic code block, extracting..." )
					jsonText = extractedJson
				end
			else
				-- Try multiline pattern with .*? equivalent
				genericCodeBlockPattern = "```.-\n(.-)\n```"
				extractedJson = string.match(responseText, genericCodeBlockPattern)
				if extractedJson then
					local trimmed = string.match(extractedJson, "^%s*(.-)%s*$")
					if string.find(trimmed, "^%s*{") and string.find(trimmed, "}%s*$") then
						logger:infof( "OllamaAPI: Found JSON-like content in multiline code block, extracting..." )
						jsonText = extractedJson
					end
				end
			end
		end
	end
	
	-- Clean up the extracted JSON text
	jsonText = string.match(jsonText, "^%s*(.-)%s*$") -- trim whitespace
	
	-- Try to parse as JSON first
	logger:infof( "OllamaAPI: Attempting to parse JSON: %s", string.sub(jsonText, 1, 200) .. (string.len(jsonText) > 200 and "..." or "") )
	local success, analysisResult = pcall( function() return JSON:decode( jsonText ) end )
	
	if success and analysisResult and type(analysisResult) == "table" then
		logger:infof( "OllamaAPI: JSON parsing successful" )
		
		-- Debug: Log the types of all fields
		logger:infof( "OllamaAPI: Field types - title: %s, caption: %s, headline: %s, instructions: %s, location: %s, keywords: %s", 
			type(analysisResult.title), type(analysisResult.caption), type(analysisResult.headline), 
			type(analysisResult.instructions), type(analysisResult.location), type(analysisResult.keywords) )
		
		-- Helper function to convert field to string
		local function fieldToString(field)
			if type(field) == "string" then
				return field
			elseif type(field) == "table" then
				-- If it's an array of strings, join them
				if #field > 0 then
					local stringParts = {}
					for i, item in ipairs(field) do
						if type(item) == "string" then
							table.insert(stringParts, item)
						end
					end
					return table.concat(stringParts, " ")
				end
				return ""
			else
				return tostring(field or "")
			end
		end
		
		-- Successfully parsed JSON response
		local results = {
			title = fieldToString(analysisResult.title),
			caption = fieldToString(analysisResult.caption),
			headline = fieldToString(analysisResult.headline) ~= "" and fieldToString(analysisResult.headline) or fieldToString(analysisResult.description),
			instructions = fieldToString(analysisResult.instructions),
			location = fieldToString(analysisResult.location),
			keywords = {}
		}
		
		-- Parse keywords into array
		local keywordsData = analysisResult.keywords or ""
		if type(keywordsData) == "table" then
			-- Keywords are already in table format
			for _, keyword in ipairs(keywordsData) do
				if type(keyword) == "string" and keyword ~= "" then
					local trimmed = string.match(keyword, "^%s*(.-)%s*$") -- trim whitespace
					if trimmed ~= "" then
						table.insert(results.keywords, { description = trimmed, selected = true })
					end
				end
			end
		elseif type(keywordsData) == "string" and keywordsData ~= "" then
			-- Keywords are in comma-separated string format
			for keyword in string.gmatch(keywordsData, "([^,]+)") do
				local trimmed = string.match(keyword, "^%s*(.-)%s*$") -- trim whitespace
				if trimmed ~= "" then
					table.insert(results.keywords, { description = trimmed, selected = true })
				end
			end
		end
		
		return results
	else
		-- Fallback to text parsing
		if not success then
			logger:errorf( "OllamaAPI: JSON parsing failed with error: %s", tostring(analysisResult) )
		else
			logger:errorf( "OllamaAPI: JSON parsing succeeded but result is not valid: %s", tostring(analysisResult) )
		end
		logger:infof( "OllamaAPI: Falling back to text parsing" )
		
		local lines = {}
		for line in string.gmatch(responseText, "[^\r\n]+") do
			local trimmed = string.match(line, "^%s*(.-)%s*$")
			if trimmed ~= "" then
				table.insert(lines, trimmed)
			end
		end
		
		local results = {
			title = "",
			caption = "",
			headline = "",
			instructions = "",
			location = "",
			keywords = {}
		}
		
		-- Look for structured patterns in the response
		for _, line in ipairs(lines) do
			local lowerLine = string.lower(line)
			
			if string.find(lowerLine, "title:") then
				results.title = string.match(line, "title:%s*(.+)") or ""
			elseif string.find(lowerLine, "caption:") then
				results.caption = string.match(line, "caption:%s*(.+)") or ""
			elseif string.find(lowerLine, "headline:") or string.find(lowerLine, "description:") then
				results.headline = string.match(line, "headline:%s*(.+)") or string.match(line, "description:%s*(.+)") or ""
			elseif string.find(lowerLine, "instructions:") then
				results.instructions = string.match(line, "instructions:%s*(.+)") or ""
			elseif string.find(lowerLine, "location:") then
				results.location = string.match(line, "location:%s*(.+)") or ""
			elseif string.find(lowerLine, "keywords:") or string.find(lowerLine, "tags:") then
				local keywordText = string.match(line, "keywords:%s*(.+)") or string.match(line, "tags:%s*(.+)") or ""
				for keyword in string.gmatch(keywordText, "([^,]+)") do
					local trimmed = string.match(keyword, "^%s*(.-)%s*$")
					if trimmed ~= "" then
						table.insert(results.keywords, { description = trimmed, selected = true })
					end
				end
			end
		end
		
		-- If we still don't have basic fields, use the first substantial lines
		if results.caption == "" and #lines > 0 then
			results.caption = lines[1]
		end
		if results.headline == "" and results.caption ~= "" then
			results.headline = results.caption
		end
		
		-- Generate some basic keywords if none were found
		if #results.keywords == 0 then
			-- Extract potential keywords from the text
			local allText = string.lower(responseText)
			local commonWords = { "the", "and", "of", "to", "a", "in", "is", "it", "you", "that", "he", "was", "for", "on", "are", "as", "with", "his", "they", "i", "at", "be", "this", "have", "from", "or", "one", "had", "by", "word", "but", "not", "what", "all", "were", "we", "when", "your", "can", "said", "there", "each", "which", "she", "do", "how", "their", "if", "will", "up", "other", "about", "out", "many", "then", "them", "these", "so", "some", "her", "would", "make", "like", "into", "him", "has", "two", "more", "very", "time", "very", "when", "come", "its", "now", "over", "think", "also", "your", "work", "life", "only", "can", "still", "should", "after", "being", "now", "made", "before", "here", "through", "when", "much", "where", "well", "get", "me", "own", "say", "she", "may", "use", "her", "than", "man", "day" }
			local wordSet = {}
			for _, word in ipairs(commonWords) do
				wordSet[word] = true
			end
			
			local words = {}
			for word in string.gmatch(allText, "%w+") do
				if string.len(word) > 3 and not wordSet[word] then
					words[word] = true
				end
			end
			
			local keywordList = {}
			for word, _ in pairs(words) do
				table.insert(keywordList, word)
				if #keywordList >= 5 then break end
			end
			
			for _, keyword in ipairs(keywordList) do
				table.insert(results.keywords, { description = keyword, selected = true })
			end
		end
		
		return results
	end
end

function OllamaAPI.analyze( fileName, photo, photoObject )
	local attempts = 0
	local baseUrl = OllamaAPI.getBaseUrl()
	local model = OllamaAPI.getModel()
	local timeout = OllamaAPI.getTimeout()
	
	while attempts <= serviceMaxRetries do
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
				-- Log what metadata we're sending to Ollama
				logger:infof( "OllamaAPI: Including EXIF/GPS metadata in analysis:" )
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

		-- Validate image data before encoding
		if not photo or photo == "" then
			local errorMsg = string.format( "Invalid image data for %s: thumbnail generation failed", fileName or "unknown file" )
			logger:errorf( "OllamaAPI: %s", errorMsg )
			return { status = false, message = errorMsg }
		end
		
		-- Encode the image data as base64
		local base64Image
		local success, result = pcall( function() return LrStringUtils.encodeBase64( photo ) end )
		if not success then
			local errorMsg = string.format( "Failed to encode image data for %s: %s", fileName or "unknown file", tostring(result) )
			logger:errorf( "OllamaAPI: %s", errorMsg )
			return { status = false, message = errorMsg }
		end
		base64Image = result
		
		-- Create the request body for Ollama API
		local reqBody = JSON:encode {
			model = model,
			prompt = prompt,
			images = { base64Image },
			stream = false,
			options = {
				temperature = 0.7,
				num_predict = 1000
			}
		}
		
		local serviceUri = string.format( "%s/api/generate", baseUrl )
		
		logger:infof( "OllamaAPI: Request attempt %d/%d to %s with model %s", attempts + 1, serviceMaxRetries + 1, baseUrl, model )
		
		-- Make HTTP call
		local resBody, resHeaders = LrHttp.post( serviceUri, reqBody, reqHeaders, "POST", timeout / 1000 )
		
		if not resBody then
			local errorMsg = "Network request failed: no response received"
			if resHeaders and resHeaders.error then
				errorMsg = string.format( "Network error: %s", resHeaders.error.name or "unknown error" )
			end
			logger:errorf( "OllamaAPI: %s", errorMsg )
			
			if attempts < serviceMaxRetries then
				attempts = attempts + 1
				local retryDelay = math.min(2^attempts, 10) -- exponential backoff, max 10 seconds
				logger:infof( "OllamaAPI: Retrying in %d seconds...", retryDelay )
				LrTasks.sleep( retryDelay )
			else
				return { status = false, message = errorMsg }
			end
		elseif resHeaders.status == 200 then
			local resJson = JSON:decode( resBody )
			if resJson and resJson.response then
				local results = { status = true }
				
				-- Debug: Log the type and content of resJson.response
				logger:infof( "OllamaAPI: Response type: %s", type(resJson.response) )
				if type(resJson.response) == "string" then
					logger:infof( "OllamaAPI: Response content: %s", string.sub(resJson.response, 1, 200) .. (string.len(resJson.response) > 200 and "..." or "") )
				else
					logger:infof( "OllamaAPI: Response is not a string: %s", tostring(resJson.response) )
				end
				
				-- Parse the response
				local analysisResult = parseResponse( resJson.response )
				
				results.title = analysisResult.title or ""
				results.caption = analysisResult.caption or ""
				results.headline = analysisResult.headline or ""
				results.instructions = analysisResult.instructions or ""
				results.location = analysisResult.location or ""
				results.keywords = analysisResult.keywords or {}
				
				logger:infof( "OllamaAPI: Analysis successful - title: %s, caption: %s, keywords: %d", 
					results.title ~= "" and "yes" or "no",
					results.caption ~= "" and "yes" or "no", 
					#results.keywords )
				
				return results
			else
				local errorMsg = "Invalid response format from Ollama"
				logger:errorf( "OllamaAPI: %s", errorMsg )
				return { status = false, message = errorMsg }
			end
		else
			local errorMsg = "Unknown error"
			if resHeaders.status then
				errorMsg = string.format( "HTTP %d error", resHeaders.status )
			end
			if resBody then
				local resJson = JSON:decode( resBody )
				if resJson and resJson.error then
					errorMsg = errorMsg .. ": " .. resJson.error
				end
			end
			logger:errorf( "OllamaAPI: %s", errorMsg )
			
			if attempts < serviceMaxRetries then
				attempts = attempts + 1
				local retryDelay = math.min(2^attempts, 10) -- exponential backoff, max 10 seconds
				logger:infof( "OllamaAPI: Retrying in %d seconds...", retryDelay )
				LrTasks.sleep( retryDelay )
			else
				return { status = false, message = errorMsg }
			end
		end
		
		attempts = attempts + 1
	end
	
	return { status = false, message = "Maximum retries exceeded" }
end

-- Batch processing with rate limiting
function OllamaAPI.analyzeBatch( photos, progressCallback )
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
			local result = OllamaAPI.analyze(photoData.fileName, photoData.jpegData, photoData.photo)
			table.insert(results, result)

			if progressCallback then
				progressCallback(i + j - 1, #photos)
			end

			-- Add delay between requests to avoid overloading the server
			if j < #batch or batchEnd < #photos then
				LrTasks.sleep(delay / 1000) -- Convert milliseconds to seconds
			end
		end
	end

	return results
end

-- Get default prompt for UI display
function OllamaAPI.getDefaultPrompt()
	return getDefaultPrompt()
end

-- Load prompt from text file
function OllamaAPI.loadPromptFromFile(filePath)
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
function OllamaAPI.getPromptPresets()
	return PromptPresets.getPresets()
end

-- Get preset names for UI dropdown
function OllamaAPI.getPresetNames()
	return PromptPresets.getPresetNames()
end

-- Get a specific preset by name
function OllamaAPI.getPreset(name)
	return PromptPresets.getPreset(name)
end