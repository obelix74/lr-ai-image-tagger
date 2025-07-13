--[[----------------------------------------------------------------------------

PromptPresets.lua
AI Image Tagger - Prompt Presets Module

Provides a collection of canned prompt presets for various photography use cases.

------------------------------------------------------------------------------]]

local PromptPresets = {}

--------------------------------------------------------------------------------

-- Sports Photography Prompt
local sportsPrompt = [[{
"keywords": "a list of relevant keywords including the jersey number for players wearing only white jerseys (comma separated). Use provided player numbers (3, 10, 11, 16, 23, 57) and names (Walter Payton, Michael Jordan, Isiah Pacheco, LeBron James, Bubba Gump, Stephan Curry) as context for identification and include associated name as a keyword from jersey number if found. Remove any keyword duplicates.",
"instructions": "Ensure the output strictly adheres to the provided JSON structure with all requested fields."
}

Please analyze this sports photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including jersey numbers and player names when identifiable
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable venues are present)

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "keyword1, keyword2, keyword3, jersey number, player name",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "venue name if identifiable"
}]]

-- Nature/Wildlife Photography Prompt
local naturePrompt = [[Please analyze this nature/wildlife photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including species names, habitat, behavior, and environmental conditions
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable landmarks or ecosystems are present)

Focus on:
- Accurate species identification when possible
- Behavioral descriptions (feeding, mating, hunting, etc.)
- Environmental context (season, weather, habitat type)
- Conservation status if known
- Technical photography aspects (lighting, composition)

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "species name, behavior, habitat, season, conservation status, photography technique",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "location name if identifiable"
}]]

-- Architecture Photography Prompt
local architecturePrompt = [[Please analyze this architectural photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including architectural style, building type, materials, and design elements
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable buildings or landmarks are present)

Focus on:
- Architectural style and period (Gothic, Modern, Art Deco, etc.)
- Building materials (steel, glass, concrete, brick, stone)
- Design elements (columns, arches, facades, rooflines)
- Structural features and engineering aspects
- Historical or cultural significance
- Lighting and perspective techniques used

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "architectural style, building type, materials, design elements, period, technique",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "building name or location if identifiable"
}]]

-- Portrait/People Photography Prompt
local portraitPrompt = [[Please analyze this portrait/people photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including mood, lighting style, composition, and setting
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable settings are present)

Focus on:
- Emotional expression and mood
- Lighting technique (natural, studio, dramatic, soft)
- Composition style (close-up, environmental, group)
- Age group and general demographics (without identifying individuals)
- Setting and context (indoor, outdoor, professional, casual)
- Photography technique and style

Note: Do not attempt to identify specific individuals by name.

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "portrait style, lighting, mood, composition, setting, age group",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "general location type if identifiable"
}]]

-- Event/Wedding Photography Prompt
local eventPrompt = [[Please analyze this event/wedding photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including event type, moments captured, emotions, and setting
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable venues are present)

Focus on:
- Type of event (wedding, celebration, ceremony, reception)
- Key moments (ceremony, first dance, cake cutting, speeches)
- Emotional content (joy, celebration, intimacy, tradition)
- Setting and decor (indoor, outdoor, formal, casual)
- Group dynamics (couple, family, guests, bridal party)
- Cultural or religious elements if present

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "event type, moment, emotion, setting, celebration, tradition",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "venue name or type if identifiable"
}]]

-- Travel/Landscape Photography Prompt
local travelPrompt = [[Please analyze this travel/landscape photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including geographical features, climate, time of day, and cultural elements
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable landmarks or regions are present)

Focus on:
- Geographical features (mountains, ocean, desert, forest, urban)
- Weather and atmospheric conditions
- Time of day and lighting quality
- Cultural landmarks or human elements
- Seasonal characteristics
- Photography techniques (long exposure, panoramic, HDR)
- Travel and tourism aspects

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "landscape type, geographical features, weather, time of day, cultural elements, technique",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "location name if identifiable landmarks present"
}]]

-- Product Photography Prompt
local productPrompt = [[Please analyze this product photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including product category, features, style, and commercial use
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable settings are present)

Focus on:
- Product category and type
- Key features and characteristics
- Style and design elements
- Commercial photography techniques
- Lighting setup and background
- Brand positioning and market appeal
- Technical specifications if visible
- Usage context and target audience

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "product type, features, style, commercial, lighting, brand, market",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "studio or setting type if identifiable"
}]]

-- Street Photography Prompt
local streetPrompt = [[Please analyze this street photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including urban elements, human activity, cultural context, and photographic style
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable urban areas or landmarks are present)

Focus on:
- Urban environment and architecture
- Human activity and social interactions
- Cultural and social context
- Street photography techniques (candid, documentary style)
- Lighting conditions (natural, artificial, mixed)
- Compositional elements (leading lines, framing, depth)
- Mood and atmosphere of the scene
- Time period indicators if present

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "street photography, urban, human activity, culture, technique, mood, architecture",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "city or area name if identifiable"
}]]

--------------------------------------------------------------------------------

-- Preset definitions
PromptPresets.presets = {
    {
        name = "Sports Photography",
        description = "Optimized for sports photos with player identification and jersey numbers",
        prompt = sportsPrompt
    },
    {
        name = "Nature & Wildlife",
        description = "Focused on species identification, behavior, and environmental context",
        prompt = naturePrompt
    },
    {
        name = "Architecture",
        description = "Emphasizes architectural styles, materials, and design elements",
        prompt = architecturePrompt
    },
    {
        name = "Portrait & People",
        description = "Captures mood, lighting, and composition without identifying individuals",
        prompt = portraitPrompt
    },
    {
        name = "Events & Weddings",
        description = "Highlights special moments, emotions, and celebration contexts",
        prompt = eventPrompt
    },
    {
        name = "Travel & Landscape",
        description = "Focuses on geographical features, cultural elements, and travel aspects",
        prompt = travelPrompt
    },
    {
        name = "Product Photography",
        description = "Commercial focus on product features, branding, and market appeal",
        prompt = productPrompt
    },
    {
        name = "Street Photography",
        description = "Urban scenes, human activity, and documentary-style capture",
        prompt = streetPrompt
    }
}

-- Get all available presets
function PromptPresets.getPresets()
    return PromptPresets.presets
end

-- Get a specific preset by name
function PromptPresets.getPreset(name)
    for _, preset in ipairs(PromptPresets.presets) do
        if preset.name == name then
            return preset
        end
    end
    return nil
end

-- Get preset names for UI dropdown
function PromptPresets.getPresetNames()
    local names = {}
    for _, preset in ipairs(PromptPresets.presets) do
        table.insert(names, preset.name)
    end
    return names
end

return PromptPresets
