--[[----------------------------------------------------------------------------

 AI Image Tagger
 Copyright 2017-2024 Tapani Otala, Enhanced by Anand Kumar Sankaran
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

local JSON = require "JSON"
require "Logger"

--------------------------------------------------------------------------------
-- Gemini AI API

GeminiAPI = { }

local httpContentType = "Content-Type"
local httpAccept = "Accept"

local mimeTypeJson = "application/json"

local keyApiKey = "GeminiAI.ApiKey"

local serviceBaseUri = "https://generativelanguage.googleapis.com/v1beta"
local serviceModel = "gemini-1.5-flash"
local serviceMaxRetries = 2

local tempPath = LrPathUtils.getStandardFilePath( "temp" )
local tempBaseName = "aiimagetagger.tmp"

--------------------------------------------------------------------------------

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
	return "Please analyze this photograph and provide:\n1. A short title (2-5 words)\n2. A brief caption (1-2 sentences)\n3. A detailed headline/description (2-3 sentences)\n4. A list of relevant keywords (comma-separated)\n5. Special instructions for photo editing or usage (if applicable)\n6. Copyright or attribution information (if visible)\n7. Location information (if identifiable landmarks are present)\n\nPlease format your response as JSON with the following structure:\n{\n  \"title\": \"short descriptive title\",\n  \"caption\": \"brief caption here\",\n  \"headline\": \"detailed headline/description here\",\n  \"keywords\": \"keyword1, keyword2, keyword3\",\n  \"instructions\": \"editing suggestions or usage notes\",\n  \"copyright\": \"copyright or attribution info if visible\",\n  \"location\": \"location name if identifiable landmarks present\"\n}"
end

local function getAnalysisPrompt()
	local prefs = LrPrefs.prefsForPlugin()
	if prefs.useCustomPrompt and prefs.customPrompt and prefs.customPrompt ~= "" then
		return prefs.customPrompt
	else
		return getDefaultPrompt()
	end
end

function GeminiAPI.analyze( fileName, photo )
	local attempts = 0
	while attempts <= serviceMaxRetries do
		local apiKey = GeminiAPI.getApiKey()
		if apiKey and apiKey ~= "" then
			local reqHeaders = {
				{ field = httpContentType, value = mimeTypeJson },
				{ field = httpAccept, value = mimeTypeJson },
			}

			-- Create the request body for Gemini API
			local reqBody = JSON:encode {
				contents = {
					{
						parts = {
							{
								text = getAnalysisPrompt()
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
			
			local serviceUri = string.format( "%s/models/%s:generateContent?key=%s", serviceBaseUri, serviceModel, apiKey )
			local resBody, resHeaders = LrHttp.post( serviceUri, reqBody, reqHeaders )
			
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
								results.copyright = analysisResult.copyright or ""
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
			local result = GeminiAPI.analyze(photoData.fileName, photoData.jpegData)
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
