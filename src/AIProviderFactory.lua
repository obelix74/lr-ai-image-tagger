--[[----------------------------------------------------------------------------

 AI Image Tagger - AI Provider Factory
 Copyright 2025 Anand's Photography
 Factory pattern for AI provider selection

--------------------------------------------------------------------------------

AIProviderFactory.lua

------------------------------------------------------------------------------]]

local LrPrefs = import "LrPrefs"
require "Logger"
require "GeminiAPI"
require "OllamaAPI"
require "OpenAIAPI"

--------------------------------------------------------------------------------
-- AI Provider Factory

AIProviderFactory = { }

-- Supported AI providers
local PROVIDERS = {
	GEMINI = "gemini",
	OLLAMA = "ollama",
	OPENAI = "openai"
}

-- Get the currently selected AI provider from preferences
function AIProviderFactory.getCurrentProvider()
	local prefs = LrPrefs.prefsForPlugin()
	return prefs.aiProvider or PROVIDERS.GEMINI
end

-- Set the AI provider in preferences
function AIProviderFactory.setCurrentProvider( provider )
	local prefs = LrPrefs.prefsForPlugin()
	if provider == PROVIDERS.GEMINI or provider == PROVIDERS.OLLAMA or provider == PROVIDERS.OPENAI then
		prefs.aiProvider = provider
		logger:infof( "AIProviderFactory: Set provider to %s", provider )
		return true
	else
		logger:errorf( "AIProviderFactory: Invalid provider: %s", tostring(provider) )
		return false
	end
end

-- Get the appropriate API module based on current provider
function AIProviderFactory.getAPI()
	local provider = AIProviderFactory.getCurrentProvider()
	
	if provider == PROVIDERS.OLLAMA then
		return OllamaAPI
	elseif provider == PROVIDERS.OPENAI then
		return OpenAIAPI
	else
		-- Default to Gemini
		return GeminiAPI
	end
end

-- Test connection for the current provider
function AIProviderFactory.testConnection()
	local provider = AIProviderFactory.getCurrentProvider()
	local api = AIProviderFactory.getAPI()
	
	logger:infof( "AIProviderFactory: Testing connection for provider: %s", provider )
	
	if provider == PROVIDERS.OLLAMA then
		return api.testConnection()
	elseif provider == PROVIDERS.OPENAI then
		return api.testConnection()
	elseif provider == PROVIDERS.GEMINI then
		-- For Gemini, just check if API key is available
		if api.hasApiKey() then
			return { status = true, message = "API key configured" }
		else
			return { status = false, message = "API key not configured" }
		end
	else
		return { status = false, message = "Unknown provider: " .. tostring(provider) }
	end
end

-- Get provider configuration status
function AIProviderFactory.getProviderStatus( provider )
	provider = provider or AIProviderFactory.getCurrentProvider()
	
	if provider == PROVIDERS.GEMINI then
		if GeminiAPI.hasApiKey() then
			return { configured = true, message = "API key configured" }
		else
			return { configured = false, message = "API key required" }
		end
	elseif provider == PROVIDERS.OLLAMA then
		local result = OllamaAPI.testConnection()
		return { configured = result.status, message = result.message }
	elseif provider == PROVIDERS.OPENAI then
		if OpenAIAPI.hasApiKey() then
			return { configured = true, message = "API key configured" }
		else
			return { configured = false, message = "API key required" }
		end
	else
		return { configured = false, message = "Unknown provider" }
	end
end

-- Get available providers with their status
function AIProviderFactory.getAvailableProviders()
	return {
		{
			id = PROVIDERS.GEMINI,
			name = "Google Gemini",
			description = "Google's Gemini AI service with vision capabilities",
			status = AIProviderFactory.getProviderStatus( PROVIDERS.GEMINI )
		},
		{
			id = PROVIDERS.OLLAMA,
			name = "Ollama (Local)",
			description = "Local Ollama server with vision models like LLaVA",
			status = AIProviderFactory.getProviderStatus( PROVIDERS.OLLAMA )
		},
		{
			id = PROVIDERS.OPENAI,
			name = "OpenAI GPT-4V",
			description = "OpenAI's GPT-4 with vision capabilities for image analysis",
			status = AIProviderFactory.getProviderStatus( PROVIDERS.OPENAI )
		}
	}
end

-- Analyze photo using current provider
function AIProviderFactory.analyze( fileName, photo, photoObject )
	local api = AIProviderFactory.getAPI()
	local provider = AIProviderFactory.getCurrentProvider()
	
	logger:infof( "AIProviderFactory: Analyzing photo %s using %s", fileName, provider )
	
	return api.analyze( fileName, photo, photoObject )
end

-- Batch analyze photos using current provider
function AIProviderFactory.analyzeBatch( photos, progressCallback )
	local api = AIProviderFactory.getAPI()
	local provider = AIProviderFactory.getCurrentProvider()
	
	logger:infof( "AIProviderFactory: Batch analyzing %d photos using %s", #photos, provider )
	
	return api.analyzeBatch( photos, progressCallback )
end

-- Get default prompt for current provider
function AIProviderFactory.getDefaultPrompt()
	local api = AIProviderFactory.getAPI()
	return api.getDefaultPrompt()
end

-- Load prompt from file for current provider
function AIProviderFactory.loadPromptFromFile( filePath )
	local api = AIProviderFactory.getAPI()
	return api.loadPromptFromFile( filePath )
end

-- Get prompt presets for current provider
function AIProviderFactory.getPromptPresets()
	local api = AIProviderFactory.getAPI()
	return api.getPromptPresets()
end

-- Get preset names for current provider
function AIProviderFactory.getPresetNames()
	local api = AIProviderFactory.getAPI()
	return api.getPresetNames()
end

-- Get specific preset for current provider
function AIProviderFactory.getPreset( name )
	local api = AIProviderFactory.getAPI()
	return api.getPreset( name )
end

-- Get version information for current provider
function AIProviderFactory.getVersions()
	local api = AIProviderFactory.getAPI()
	return api.getVersions()
end

-- Provider constants for external use
AIProviderFactory.PROVIDERS = PROVIDERS