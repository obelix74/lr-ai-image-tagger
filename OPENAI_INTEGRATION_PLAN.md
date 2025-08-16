# OpenAI API Integration Plan for Lightroom AI Image Tagger

## Overview

This document outlines the comprehensive plan to add OpenAI API support to the Lightroom AI Image Tagger plugin. The implementation will follow the established factory pattern architecture and maintain full compatibility with existing Gemini and Ollama providers.

## Current Architecture

```
AIProviderFactory.lua (Factory Pattern)
    |
    +-- GeminiAPI.lua (Google Gemini)
    +-- OllamaAPI.lua (Local Ollama)  
    +-- [NEW] OpenAIAPI.lua (OpenAI GPT-4V)
```

## Implementation Phases

### Phase 1: Core OpenAI API Module

**File: `src/OpenAIAPI.lua`**

This module will implement the standard provider interface following the pattern established by `GeminiAPI.lua` and `OllamaAPI.lua`.

#### Required Interface Methods

- `analyze(fileName, photo, photoObject)` - Single image analysis
- `analyzeBatch(photos, progressCallback)` - Batch processing with rate limiting
- `testConnection()` - Validate API connectivity and model availability
- `storeApiKey(apiKey)` / `clearApiKey()` / `getApiKey()` / `hasApiKey()` - API key management
- `getDefaultPrompt()` - Return default analysis prompt
- `getVersions()` - API version information
- `loadPromptFromFile(filePath)` - Load custom prompts
- `getPromptPresets()` / `getPresetNames()` / `getPreset(name)` - Prompt preset management

#### Technical Specifications

- **API Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Authentication**: Bearer token in Authorization header
- **Supported Models**: `gpt-4-vision-preview`, `gpt-4o`, `gpt-4o-mini`
- **Request Format**: Chat completions API with vision capabilities
- **Response Processing**: JSON parsing with markdown code block handling

### Phase 2: Factory Pattern Integration

**File: `src/AIProviderFactory.lua`**

#### Required Changes

```lua
-- Add OpenAI to providers constant
local PROVIDERS = {
    GEMINI = "gemini",
    OLLAMA = "ollama",
    OPENAI = "openai"  -- NEW
}

-- Import OpenAI module
require "OpenAIAPI"

-- Update getAPI() function
function AIProviderFactory.getAPI()
    local provider = AIProviderFactory.getCurrentProvider()
    
    if provider == PROVIDERS.OLLAMA then
        return OllamaAPI
    elseif provider == PROVIDERS.OPENAI then
        return OpenAIAPI  -- NEW
    else
        -- Default to Gemini
        return GeminiAPI
    end
end
```

#### Integration Points

- Add OpenAI branch to provider validation in `setCurrentProvider()`
- Update `testConnection()` to handle OpenAI-specific connection testing
- Modify `getProviderStatus()` to check OpenAI API key availability
- Ensure `getAvailableProviders()` includes OpenAI provider information

### Phase 3: Configuration Management

**File: `src/AiTaggerInit.lua` or preferences initialization**

#### New Preference Keys

```lua
-- OpenAI-specific preferences
prefs.openaiModel = "gpt-4o"                    -- Default model
prefs.openaiTimeout = 30000                     -- Request timeout (ms)
prefs.openaiMaxTokens = 1000                    -- Response token limit
prefs.openaiTemperature = 0.7                   -- Creativity setting (0-1)
prefs.openaiRetryAttempts = 3                   -- Max retry attempts
prefs.openaiRetryDelay = 2000                   -- Base retry delay (ms)
```

#### API Key Storage

```lua
-- Follow existing pattern from GeminiAPI.lua
local keyApiKey = "OpenAI.ApiKey"

function OpenAIAPI.storeApiKey(apiKey)
    math.randomseed(LrDate.currentTime())
    local salt = tostring(math.random() * 100000)
    local prefs = LrPrefs.prefsForPlugin()
    prefs.openaiSalt = salt
    LrPasswords.store(keyApiKey, apiKey, salt)
end

function OpenAIAPI.getApiKey()
    local prefs = LrPrefs.prefsForPlugin()
    local salt = prefs.openaiSalt
    return LrPasswords.retrieve(keyApiKey, salt)
end
```

### Phase 4: Request/Response Processing

#### OpenAI Request Structure

```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user", 
      "content": [
        {
          "type": "text", 
          "text": "Please analyze this photograph and provide: [analysis prompt]"
        },
        {
          "type": "image_url", 
          "image_url": {
            "url": "data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAA..."
          }
        }
      ]
    }
  ],
  "max_tokens": 1000,
  "temperature": 0.7
}
```

#### Response Processing Logic

```lua
local function parseOpenAIResponse(responseText)
    -- Handle potential markdown code block wrapping
    local jsonText = responseText
    
    -- Extract from ```json blocks if present
    local codeBlockPattern = "```json%s*(.-)%s*```"
    local extractedJson = string.match(responseText, codeBlockPattern)
    if extractedJson then
        jsonText = extractedJson
    end
    
    -- Parse JSON and extract metadata fields
    local success, analysisResult = pcall(function() 
        return JSON:decode(jsonText) 
    end)
    
    if success and analysisResult then
        return {
            title = analysisResult.title or "",
            caption = analysisResult.caption or "",
            headline = analysisResult.headline or "",
            instructions = analysisResult.instructions or "",
            location = analysisResult.location or "",
            keywords = parseKeywords(analysisResult.keywords or "")
        }
    end
    
    -- Fallback to text parsing if JSON fails
    return parseTextResponse(responseText)
end
```

## Key Implementation Details

### Error Handling Strategy

```lua
-- HTTP Status Code Handling
if resHeaders.status == 401 then
    -- Invalid API key
    logger:warnf("OpenAI: authorization failure, invalid API key")
    return { status = false, message = "Invalid API key" }
elseif resHeaders.status == 429 then
    -- Rate limit exceeded
    local retryAfter = resHeaders["retry-after"] or "60"
    logger:warnf("OpenAI: rate limit exceeded, retry after %s seconds", retryAfter)
    return { status = false, message = "Rate limit exceeded" }
elseif resHeaders.status == 400 then
    -- Bad request
    local errorDetails = parseErrorResponse(resBody)
    logger:errorf("OpenAI: bad request - %s", errorDetails)
    return { status = false, message = errorDetails }
end
```

### Rate Limiting Implementation

```lua
local function implementRetryLogic(attempts, maxRetries)
    if attempts < maxRetries then
        local delay = math.min(2^attempts, 60) -- Exponential backoff, max 60s
        logger:infof("OpenAI: Retrying in %d seconds (attempt %d/%d)", 
                     delay, attempts + 1, maxRetries)
        LrTasks.sleep(delay)
        return true
    end
    return false
end
```

### Image Processing

```lua
function OpenAIAPI.analyze(fileName, photo, photoObject)
    -- Validate image data
    if not photo or photo == "" then
        return { status = false, message = "Invalid image data" }
    end
    
    -- Encode image as base64
    local base64Image = LrStringUtils.encodeBase64(photo)
    
    -- Build request with image content
    local reqBody = JSON:encode({
        model = getSelectedModel(),
        messages = {
            {
                role = "user",
                content = {
                    { type = "text", text = getAnalysisPrompt() },
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
    })
    
    -- Make API request with proper headers
    local reqHeaders = {
        { field = "Content-Type", value = "application/json" },
        { field = "Authorization", value = "Bearer " .. getApiKey() }
    }
    
    local resBody, resHeaders = LrHttp.post(
        "https://api.openai.com/v1/chat/completions", 
        reqBody, 
        reqHeaders
    )
    
    -- Process response
    return processOpenAIResponse(resBody, resHeaders)
end
```

### Hierarchical Keywords Support

```lua
local function parseKeywords(keywordsStr)
    local keywords = {}
    if not keywordsStr or keywordsStr == "" then
        return keywords
    end
    
    -- Split by comma and process each keyword
    for keyword in string.gmatch(keywordsStr, "([^,]+)") do
        local trimmed = string.match(keyword, "^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(keywords, { 
                description = trimmed, 
                selected = true 
            })
        end
    end
    
    return keywords
end
```

## Testing Strategy

### Unit Testing Requirements

1. **API Key Management Testing**
   - Secure storage and retrieval with LrPasswords
   - API key format validation
   - Authentication header construction
   - Key clearing and error handling

2. **Request Formation Testing**
   - JSON structure validation for chat completions API
   - Base64 image encoding accuracy
   - Message format with text + image content
   - Model parameter passing and configuration

3. **Response Processing Testing**
   - JSON parsing for various OpenAI response formats
   - Metadata field extraction (title, caption, headline, etc.)
   - Keyword array conversion and hierarchical support
   - Edge cases (empty responses, malformed JSON, markdown wrapping)

### Integration Testing Strategy

1. **End-to-End Image Analysis**
   - Test with various image types (RAW, JPEG, TIFF)
   - Validate metadata extraction and EXIF integration
   - Test batch processing with rate limiting
   - Verify UI integration and result display

2. **Provider Factory Integration**
   - Test provider switching between Gemini, Ollama, and OpenAI
   - Validate configuration persistence and restoration
   - Test error handling across different provider states

3. **Performance Testing**
   - Compare response times against Gemini and Ollama
   - Test batch processing efficiency with OpenAI rate limits
   - Validate memory usage during large image processing
   - Test network timeout handling and retry mechanisms

### Error Scenario Testing

- Invalid API keys and authentication failures
- Network connectivity issues and timeouts
- Rate limit exceeded scenarios with retry logic
- Malformed responses and JSON parsing failures
- Service unavailability and graceful degradation
- Image size/format limitations and handling

## Implementation Timeline

### Day 1: Core Infrastructure
- Create `OpenAIAPI.lua` skeleton with all required interface methods
- Implement API key management using LrPasswords pattern
- Build basic `testConnection()` function
- Validate OpenAI API access with simple request

### Day 2: API Integration
- Implement `analyze()` method with chat completions API
- Build response parsing logic for JSON extraction
- Add metadata field mapping to plugin format
- Test basic image analysis workflow end-to-end

### Day 3: Factory Integration
- Update `AIProviderFactory.lua` to include OpenAI provider
- Add model selection preferences and configuration
- Implement batch processing with rate limiting
- Test provider switching functionality

### Day 4: Testing & Polish
- Comprehensive testing across different scenarios
- Error handling validation and edge case testing
- Performance comparison with existing providers
- Documentation updates and final integration testing

## Risk Mitigation Strategies

### Technical Risks

- **API Format Changes**: Maintain flexible response parsing to handle OpenAI format variations
- **Rate Limiting Issues**: Implement conservative batch sizing and exponential backoff
- **Memory Constraints**: Optimize base64 encoding for large images
- **Token Limits**: Monitor prompt + response token usage and implement truncation if needed

### Integration Risks

- **UI Compatibility**: Follow exact patterns from existing provider configurations
- **Preference Conflicts**: Use unique preference keys to avoid collision with existing settings
- **Provider Switching**: Ensure clean state management when changing providers
- **Backward Compatibility**: Maintain compatibility with existing saved preferences

### Timeline Risks

- **API Access Delays**: Have backup OpenAI account ready for testing
- **Complex Error Cases**: Allocate extra time for comprehensive error handling
- **Performance Issues**: Plan for optimization if initial implementation is slow
- **Testing Complications**: Prepare diverse test image set for thorough validation

## Success Criteria

- **Functional Parity**: OpenAI provider works identically to existing Gemini/Ollama providers
- **Easy Configuration**: Simple API key setup with intuitive model selection
- **Reliable Performance**: Comparable analysis quality and reasonable response times
- **Robust Error Handling**: Graceful failures with helpful, user-friendly error messages
- **Future Compatibility**: Architecture supports additional OpenAI models and features

## File Structure Summary

### New Files to Create

- `src/OpenAIAPI.lua` - Core OpenAI integration module

### Existing Files to Modify

- `src/AIProviderFactory.lua` - Add OpenAI provider support
- `src/AiTaggerInit.lua` - Initialize OpenAI preferences (if this file exists)

### Files to Reference for Patterns

- `src/GeminiAPI.lua` - API integration patterns and interface compliance
- `src/OllamaAPI.lua` - Alternative provider implementation example
- `src/AiTaggerMenuItem.lua` - UI integration and provider usage patterns

## Future Enhancements

### Potential OpenAI-Specific Features

- **Model Selection UI**: Dropdown for choosing between GPT-4V, GPT-4o, GPT-4o-mini
- **Cost Tracking**: Monitor API usage and estimated costs
- **Advanced Prompting**: Support for system messages and conversation context
- **Fine-tuning Support**: Integration with custom-trained OpenAI models
- **Batch API**: Utilize OpenAI's batch processing API for cost savings

### Architecture Improvements

- **Abstract Provider Base**: Create common base class to reduce code duplication
- **Plugin Configuration**: Centralized configuration management for all providers
- **Performance Monitoring**: Built-in performance metrics and comparison tools
- **Async Processing**: Enhanced concurrent request handling for better performance

## Conclusion

This implementation plan provides a comprehensive roadmap for adding OpenAI API support while maintaining the plugin's architectural integrity and user experience standards. The factory pattern approach ensures clean separation of concerns and easy maintenance, while the phased implementation strategy minimizes risk and allows for iterative testing and refinement.

The plan leverages existing patterns and interfaces to ensure consistency across all AI providers, while taking advantage of OpenAI's specific capabilities for enhanced image analysis quality.