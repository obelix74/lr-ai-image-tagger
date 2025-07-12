--[[----------------------------------------------------------------------------

 RoboTagger
 Copyright 2017-2024 Tapani Otala
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
local tempBaseName = "robotagger.tmp"

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
								text = "Please analyze this photograph and provide:\n1. A brief caption (1-2 sentences)\n2. A detailed description (2-3 sentences)\n3. A list of relevant keywords (comma-separated)\n\nPlease format your response as JSON with the following structure:\n{\n  \"caption\": \"brief caption here\",\n  \"description\": \"detailed description here\",\n  \"keywords\": \"keyword1, keyword2, keyword3\"\n}"
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
					responseMimeType = "application/json"
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
								results.caption = analysisResult.caption or ""
								results.description = analysisResult.description or ""
								
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
								results.caption = ""
								results.description = ""
								results.keywords = {}
							end
						else
							results.caption = ""
							results.description = ""
							results.keywords = {}
						end
					else
						results.caption = ""
						results.description = ""
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
