--[[----------------------------------------------------------------------------

PromptPresets.lua
AI Image Tagger - Prompt Presets Module

Provides a collection of canned prompt presets for various photography use cases.

------------------------------------------------------------------------------]]

local PromptPresets = {}

--------------------------------------------------------------------------------

-- Sports Photography Prompt
local sportsPrompt = [[Please analyze this sports photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including sport type, action, players, equipment, and venue details
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable venues are present)

Focus on:
- Sport identification (football, basketball, soccer, baseball, tennis, etc.)
- Action and movement (running, jumping, throwing, catching, scoring)
- Player details (jersey numbers if visible, team colors, positions)
- Equipment and gear (balls, bats, rackets, protective gear)
- Venue characteristics (stadium, field, court, arena, outdoor/indoor)
- Game situation (offense, defense, celebration, timeout)
- Crowd and atmosphere
- Lighting conditions and photography technique

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "sport name, action, player details, equipment, venue, team colors, jersey numbers",
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

-- Automotive Photography Prompt
local automotivePrompt = [[Please analyze this automotive photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including vehicle type, brand, model, features, and automotive context
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable venues or settings are present)

Focus on:
- Vehicle identification (make, model, year if discernible)
- Automotive features (design elements, modifications, condition)
- Photography context (show, race, street, studio, lifestyle)
- Technical aspects (lighting, angles, composition)
- Setting and environment (track, street, garage, showroom)
- Automotive culture and community elements
- Performance and aesthetic details

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "vehicle type, brand, automotive, photography style, setting, features",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "venue or location if identifiable"
}]]

-- Food Photography Prompt
local foodPrompt = [[Please analyze this food photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including cuisine type, ingredients, presentation style, and culinary context
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable restaurants or venues are present)

Focus on:
- Food identification (dish type, cuisine style, ingredients)
- Presentation and plating style
- Photography technique (overhead, close-up, styled, natural)
- Lighting quality (natural, artificial, mood lighting)
- Setting context (restaurant, home, studio, outdoor)
- Cultural and culinary significance
- Appetite appeal and visual composition
- Garnishes and accompaniments

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "cuisine type, dish name, ingredients, presentation, photography style, setting",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "restaurant or venue name if identifiable"
}]]

-- Fashion Photography Prompt
local fashionPrompt = [[Please analyze this fashion photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including fashion elements, style, mood, and photographic technique
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable settings are present)

Focus on:
- Fashion elements (clothing, accessories, styling)
- Photography style (editorial, commercial, street fashion, portrait)
- Mood and aesthetic (elegant, edgy, casual, formal, avant-garde)
- Lighting and composition techniques
- Color palette and styling choices
- Setting and background context
- Fashion trends and style periods
- Model pose and expression (without identifying individuals)

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "fashion style, clothing type, mood, photography technique, aesthetic, setting",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "location type if identifiable"
}]]

-- Macro Photography Prompt
local macroPrompt = [[Please analyze this macro photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including subject type, technical details, and macro photography elements
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable environments are present)

Focus on:
- Subject identification (insects, flowers, textures, objects)
- Macro photography techniques (magnification, depth of field, focus stacking)
- Technical details (lighting, background, composition)
- Texture and detail emphasis
- Scientific or artistic value
- Equipment considerations and settings
- Natural vs. studio environment
- Seasonal or temporal context

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "macro photography, subject type, technique, detail, texture, magnification",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "environment type if identifiable"
}]]

-- Abstract Photography Prompt
local abstractPrompt = [[Please analyze this abstract photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including visual elements, techniques, and artistic concepts
5. Special instructions for photo editing or usage
6. Copyright or attribution information (if visible)
7. Location information (if identifiable sources are present)

Focus on:
- Visual elements (shapes, lines, patterns, textures, colors)
- Abstract techniques (blur, multiple exposure, reflection, shadow)
- Artistic concepts and interpretation
- Compositional elements and balance
- Emotional or conceptual impact
- Source material (if discernible)
- Photography techniques used
- Color theory and visual harmony

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "abstract photography, visual elements, technique, artistic concept, composition",
  "instructions": "editing suggestions or usage notes",
  "copyright": "copyright or attribution info if visible",
  "location": "source location if identifiable"
}]]

--------------------------------------------------------------------------------

-- Preset definitions
PromptPresets.presets = {
    {
        name = "Sports Photography",
        description = "Comprehensive sports analysis including action, players, equipment, and venues",
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
    },
    {
        name = "Automotive Photography",
        description = "Vehicle identification, automotive features, and car culture contexts",
        prompt = automotivePrompt
    },
    {
        name = "Food Photography",
        description = "Cuisine identification, presentation style, and culinary contexts",
        prompt = foodPrompt
    },
    {
        name = "Fashion Photography",
        description = "Fashion elements, style analysis, and aesthetic mood capture",
        prompt = fashionPrompt
    },
    {
        name = "Macro Photography",
        description = "Close-up subjects, technical details, and magnification techniques",
        prompt = macroPrompt
    },
    {
        name = "Abstract Photography",
        description = "Visual elements, artistic concepts, and creative interpretation",
        prompt = abstractPrompt
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
