#!/usr/bin/env lua

-- Simple test script to validate OpenAI integration structure
-- This tests the module loading and basic interface compliance

print("Testing OpenAI Integration...")

-- Mock Lightroom SDK imports (for testing outside Lightroom)
local function mockLrModule(name)
    return {
        currentTime = function() return os.time() end,
        numberToStringWithSeparators = function(num) return tostring(num) end,
        encodeBase64 = function(data) return "base64_encoded_data" end,
        trimWhitespace = function(str) return str:match("^%s*(.-)%s*$") end,
        post = function() return nil, {status = 200} end,
        get = function() return nil, {status = 200} end,
        store = function() end,
        retrieve = function() return "test_key" end,
        prefsForPlugin = function() return {} end
    }
end

-- Mock the import function
_G.import = mockLrModule

-- Mock required modules
_G.JSON = {
    encode = function(obj) return '{"test": "json"}' end,
    decode = function(str) return {test = "json"} end
}

_G.logger = {
    infof = function(fmt, ...) print(string.format("INFO: " .. fmt, ...)) end,
    errorf = function(fmt, ...) print(string.format("ERROR: " .. fmt, ...)) end,
    warnf = function(fmt, ...) print(string.format("WARN: " .. fmt, ...)) end,
    tracef = function(fmt, ...) print(string.format("TRACE: " .. fmt, ...)) end
}

_G.PromptPresets = {
    getPresets = function() return {} end,
    getPresetNames = function() return {} end,
    getPreset = function(name) return nil end
}

-- Load the OpenAI module
dofile("src/OpenAIAPI.lua")

-- Test basic interface compliance
local function testInterface()
    print("Testing OpenAI interface compliance...")
    
    local required_methods = {
        "getVersions",
        "storeApiKey", 
        "clearApiKey",
        "getApiKey",
        "hasApiKey",
        "testConnection",
        "analyze",
        "analyzeBatch",
        "getDefaultPrompt",
        "loadPromptFromFile",
        "getPromptPresets",
        "getPresetNames",
        "getPreset"
    }
    
    local missing_methods = {}
    
    for _, method in ipairs(required_methods) do
        if type(OpenAIAPI[method]) ~= "function" then
            table.insert(missing_methods, method)
        else
            print("✓ " .. method .. " found")
        end
    end
    
    if #missing_methods > 0 then
        print("✗ Missing methods: " .. table.concat(missing_methods, ", "))
        return false
    else
        print("✓ All required methods implemented")
        return true
    end
end

-- Test provider factory integration
local function testFactoryIntegration()
    print("Testing factory integration...")
    
    -- Load factory
    dofile("src/AIProviderFactory.lua")
    
    -- Check if OpenAI is in providers list
    local providers = AIProviderFactory.getAvailableProviders()
    local openai_found = false
    
    for _, provider in ipairs(providers) do
        if provider.id == "openai" then
            openai_found = true
            print("✓ OpenAI provider found in factory: " .. provider.name)
            break
        end
    end
    
    if not openai_found then
        print("✗ OpenAI provider not found in factory")
        return false
    end
    
    return true
end

-- Run tests
local interface_ok = testInterface()
local factory_ok = testFactoryIntegration()

if interface_ok and factory_ok then
    print("\n✓ OpenAI integration tests PASSED")
    print("✓ Ready for testing in Lightroom")
    os.exit(0)
else
    print("\n✗ OpenAI integration tests FAILED")
    os.exit(1)
end