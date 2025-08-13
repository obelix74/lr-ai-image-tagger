--[[----------------------------------------------------------------------------

PromptPresets.lua
AI Image Tagger - Prompt Presets Module

Provides a collection of canned prompt presets for various photography use cases.

------------------------------------------------------------------------------]]

local PromptPresets = {}

--------------------------------------------------------------------------------


-- Add language instruction to a prompt
local function addLanguageInstruction(prompt)
	local LrPrefs = import "LrPrefs"
	local prefs = LrPrefs.prefsForPlugin()
	local language = prefs.responseLanguage or "English"
	
	if language ~= "English" then
		local languageInstruction = string.format("IMPORTANT: Please respond in %s language. All text fields (title, caption, headline, keywords, instructions, location) should be in %s.\n\n", language, language)
		return languageInstruction .. prompt
	end
	return prompt
end

-- Add hierarchical keyword instruction to a prompt
local function addHierarchicalKeywordInstruction(prompt)
	local LrPrefs = import "LrPrefs"
	local prefs = LrPrefs.prefsForPlugin()
	
	if prefs.useHierarchicalKeywords then
		local hierarchicalInstruction = [[

HIERARCHICAL KEYWORDS: For keywords, use hierarchical format with " > " separator to organize from broad to specific categories:
- Start with broad categories (e.g., Nature, Sports, Architecture, Photography)
- Progress to specific subcategories (e.g., Wildlife, Team Sports, Modern Architecture, Portrait Photography)
- End with detailed descriptors (e.g., Birds, Football, Glass Building, Studio Portrait)
- Examples: "Nature > Wildlife > Birds > Eagles", "Sports > Team Sports > Football", "Photography > Portrait Photography > Studio"
- Include 8-12 hierarchical keywords total
- Use the separator " > " between hierarchy levels
- Separate different keyword hierarchies with commas

]]
		return prompt .. hierarchicalInstruction
	end
	return prompt
end

--------------------------------------------------------------------------------

-- Sports Photography Prompt
local sportsPrompt = [[Please analyze this sports photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable venues are present)

Focus on:
- Sport identification (football, basketball, soccer, baseball, tennis, etc.)
- Action and movement (running, jumping, throwing, catching, scoring)
- Player details (jersey numbers if visible, team colors, positions)
- Equipment and gear (balls, bats, rackets, protective gear)
- Venue characteristics (stadium, field, court, arena, outdoor/indoor)
- Game situation (offense, defense, celebration, timeout)
- Crowd and atmosphere
- Lighting conditions and photography technique

For keywords, use hierarchical format with " > " separator (e.g., "Sports > Team Sports > Football", "Sports > Equipment > Ball", "Sports > Actions > Running", "Photography > Sports Photography > Action Shot"):
- Start with broad categories (Sports, Photography, Equipment)
- Progress to specific subcategories
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Sports > Team Sports > Football, Sports > Actions > Running, Sports > Equipment > Ball, Photography > Sports Photography > Action Shot",
  "instructions": "editing suggestions or usage notes",
  "location": "venue name if identifiable"
}]]

-- Nature/Wildlife Photography Prompt
local naturePrompt = [[Please analyze this nature/wildlife photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable landmarks or ecosystems are present)

Focus on:
- Accurate species identification when possible
- Behavioral descriptions (feeding, mating, hunting, etc.)
- Environmental context (season, weather, habitat type)
- Conservation status if known
- Technical photography aspects (lighting, composition)

For keywords, use hierarchical format with " > " separator (e.g., "Nature > Wildlife > Birds > Eagles", "Nature > Habitats > Forest > Deciduous", "Nature > Behavior > Feeding", "Photography > Wildlife Photography > Telephoto"):
- Start with broad categories (Nature, Wildlife, Photography, Environment)
- Progress to specific subcategories and species classifications
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Nature > Wildlife > Birds > Eagles, Nature > Habitats > Forest, Nature > Behavior > Feeding, Photography > Wildlife Photography > Telephoto",
  "instructions": "editing suggestions or usage notes",
  "location": "location name if identifiable"
}]]

-- Architecture Photography Prompt
local architecturePrompt = [[Please analyze this architectural photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable buildings or landmarks are present)

Focus on:
- Architectural style and period (Gothic, Modern, Art Deco, etc.)
- Building materials (steel, glass, concrete, brick, stone)
- Design elements (columns, arches, facades, rooflines)
- Structural features and engineering aspects
- Historical or cultural significance
- Lighting and perspective techniques used

For keywords, use hierarchical format with " > " separator (e.g., "Architecture > Styles > Modern", "Architecture > Materials > Glass", "Architecture > Elements > Facade", "Photography > Architectural Photography > Perspective"):
- Start with broad categories (Architecture, Construction, Photography, Design)
- Progress to specific styles, materials, and elements
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Architecture > Styles > Modern, Architecture > Materials > Glass, Architecture > Elements > Facade, Photography > Architectural Photography > Perspective",
  "instructions": "editing suggestions or usage notes",
  "location": "building name or location if identifiable"
}]]

-- Portrait/People Photography Prompt
local portraitPrompt = [[Please analyze this portrait/people photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including mood, lighting style, composition, and setting
5. Special instructions for photo editing or usage
6. Location information (if identifiable settings are present)

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
  "location": "general location type if identifiable"
}]]

-- Event/Wedding Photography Prompt
local eventPrompt = [[Please analyze this event/wedding photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including event type, moments captured, emotions, and setting
5. Special instructions for photo editing or usage
6. Location information (if identifiable venues are present)

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
  "location": "venue name or type if identifiable"
}]]

-- Travel/Landscape Photography Prompt
local travelPrompt = [[Please analyze this travel/landscape photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including geographical features, climate, time of day, and cultural elements
5. Special instructions for photo editing or usage
6. Location information (if identifiable landmarks or regions are present)

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
  "location": "location name if identifiable landmarks present"
}]]

-- Product Photography Prompt
local productPrompt = [[Please analyze this product photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including product category, features, style, and commercial use
5. Special instructions for photo editing or usage
6. Location information (if identifiable settings are present)

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
  "location": "studio or setting type if identifiable"
}]]

-- Street Photography Prompt
local streetPrompt = [[Please analyze this street photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including urban elements, human activity, cultural context, and photographic style
5. Special instructions for photo editing or usage
6. Location information (if identifiable urban areas or landmarks are present)

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
  "location": "city or area name if identifiable"
}]]

-- Automotive Photography Prompt
local automotivePrompt = [[Please analyze this automotive photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including vehicle type, brand, model, features, and automotive context
5. Special instructions for photo editing or usage
6. Location information (if identifiable venues or settings are present)

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
  "location": "venue or location if identifiable"
}]]

-- Food Photography Prompt
local foodPrompt = [[Please analyze this food photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including cuisine type, ingredients, presentation style, and culinary context
5. Special instructions for photo editing or usage
6. Location information (if identifiable restaurants or venues are present)

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
  "location": "restaurant or venue name if identifiable"
}]]

-- Fashion Photography Prompt
local fashionPrompt = [[Please analyze this fashion photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including fashion elements, style, mood, and photographic technique
5. Special instructions for photo editing or usage
6. Location information (if identifiable settings are present)

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
  "location": "location type if identifiable"
}]]

-- Macro Photography Prompt
local macroPrompt = [[Please analyze this macro photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including subject type, technical details, and macro photography elements
5. Special instructions for photo editing or usage
6. Location information (if identifiable environments are present)

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
  "location": "environment type if identifiable"
}]]

-- Abstract Photography Prompt
local abstractPrompt = [[Please analyze this abstract photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords including visual elements, techniques, and artistic concepts
5. Special instructions for photo editing or usage
6. Location information (if identifiable sources are present)

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
  "location": "source location if identifiable"
}]]

-- Astrophotography Prompt
local astrophotographyPrompt = [[Please analyze this astrophotography image and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable observatories or locations are present)

Focus on:
- Celestial object identification (stars, planets, galaxies, nebulae, moon phases)
- Constellation names and astronomical events
- Technical aspects (long exposure, star trails, light pollution effects)
- Equipment considerations (telescope, tracking mount, filters)
- Time and seasonal context (meteor showers, celestial events)
- Deep sky objects and their characteristics
- Light pollution and dark sky conditions
- Post-processing techniques specific to astrophotography

For keywords, use hierarchical format with " > " separator (e.g., "Astronomy > Deep Sky > Nebulae > Orion Nebula", "Photography > Astrophotography > Long Exposure", "Celestial Objects > Stars > Constellations > Ursa Major"):
- Start with broad categories (Astronomy, Photography, Celestial Objects)
- Progress to specific object types and techniques
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Astronomy > Deep Sky > Nebulae, Photography > Astrophotography > Long Exposure, Celestial Objects > Stars > Constellations, Equipment > Telescope > Reflector",
  "instructions": "editing suggestions or usage notes",
  "location": "observatory or location name if identifiable"
}]]

-- Concert/Music Photography Prompt
local concertPrompt = [[Please analyze this concert/music photography image and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable venues are present)

Focus on:
- Music genre identification (rock, jazz, classical, electronic, hip-hop)
- Performance elements (singing, instrumental, stage presence, crowd interaction)
- Stage lighting effects (spotlights, color washes, strobes, atmospheric lighting)
- Venue characteristics (arena, club, festival, outdoor, intimate)
- Instruments and equipment (guitars, drums, microphones, amplifiers)
- Crowd energy and audience interaction
- Performance moments (solos, crowd shots, backstage, sound check)
- Technical challenges (low light, motion blur, dramatic contrast)

For keywords, use hierarchical format with " > " separator (e.g., "Music > Genres > Rock", "Performance > Live Music > Concert", "Photography > Concert Photography > Stage Lighting", "Venues > Concert Halls > Arena"):
- Start with broad categories (Music, Performance, Photography, Equipment)
- Progress to specific genres and venue types
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Music > Genres > Rock, Performance > Live Music > Concert, Photography > Concert Photography > Stage Lighting, Venues > Concert Halls > Arena",
  "instructions": "editing suggestions or usage notes",
  "location": "venue name if identifiable"
}]]

-- Documentary Photography Prompt
local documentaryPrompt = [[Please analyze this documentary photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable locations or contexts are present)

Focus on:
- Social and cultural themes (community, tradition, change, conflict)
- Human stories and authentic moments
- Historical or contemporary significance
- Environmental and social conditions
- Photojournalistic approach and ethics
- Cultural documentation and preservation
- Social issues and human rights
- Authentic emotional expression and interaction
- Documentary storytelling techniques
- Context and background information

For keywords, use hierarchical format with " > " separator (e.g., "Documentary > Social Issues > Community", "Photography > Photojournalism > Human Interest", "Culture > Traditions > Ceremonies", "Society > Social Change > Urban Development"):
- Start with broad categories (Documentary, Photography, Culture, Society)
- Progress to specific themes and contexts
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Documentary > Social Issues > Community, Photography > Photojournalism > Human Interest, Culture > Traditions > Ceremonies, Society > Social Change > Development",
  "instructions": "editing suggestions or usage notes",
  "location": "location or community name if identifiable"
}]]

-- Pet/Animal Photography Prompt
local petPrompt = [[Please analyze this pet/animal photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable settings are present)

Focus on:
- Animal species and breed identification (dogs, cats, birds, exotic pets)
- Animal behavior and expressions (playful, alert, sleeping, interacting)
- Human-animal relationships and bonding moments
- Pet characteristics (age, size, color, markings, personality traits)
- Photography techniques (eye-level shots, action shots, portraits)
- Setting context (home, park, studio, veterinary, grooming)
- Seasonal activities and environments
- Training and obedience moments
- Pet accessories and toys

For keywords, use hierarchical format with " > " separator (e.g., "Animals > Domestic > Dogs > Golden Retriever", "Photography > Pet Photography > Portrait", "Behavior > Animal Behavior > Playing", "Settings > Indoor > Home"):
- Start with broad categories (Animals, Photography, Behavior, Settings)
- Progress to specific species and breeds
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Animals > Domestic > Dogs > Golden Retriever, Photography > Pet Photography > Portrait, Behavior > Animal Behavior > Playing, Settings > Indoor > Home",
  "instructions": "editing suggestions or usage notes",
  "location": "setting or location type if identifiable"
}]]

-- Medical/Scientific Photography Prompt
local medicalPrompt = [[Please analyze this medical/scientific photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable facilities are present)

Focus on:
- Medical procedures and clinical documentation
- Scientific specimens and research materials
- Laboratory equipment and instruments
- Healthcare environments and facilities
- Anatomical and physiological features
- Research and educational contexts
- Microscopic and macro-level observations
- Clinical and diagnostic imaging
- Safety protocols and sterile environments
- Educational and training applications

For keywords, use hierarchical format with " > " separator (e.g., "Medicine > Clinical > Procedures", "Science > Research > Laboratory", "Photography > Medical Photography > Documentation", "Equipment > Medical Devices > Diagnostic"):
- Start with broad categories (Medicine, Science, Photography, Equipment)
- Progress to specific fields and applications
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Medicine > Clinical > Procedures, Science > Research > Laboratory, Photography > Medical Photography > Documentation, Equipment > Medical Devices > Diagnostic",
  "instructions": "editing suggestions or usage notes",
  "location": "facility or institution type if identifiable"
}]]

-- Real Estate Photography Prompt
local realEstatePrompt = [[Please analyze this real estate photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable neighborhoods or areas are present)

Focus on:
- Property types (residential, commercial, luxury, starter homes)
- Interior spaces and room identification (kitchen, bathroom, bedroom, living areas)
- Architectural features and design elements
- Property condition and staging quality
- Lighting quality and natural illumination
- Outdoor spaces (gardens, patios, pools, landscapes)
- Neighborhood characteristics and amenities
- Property size and spatial relationships
- Design styles and finishing materials
- Market appeal and target demographics

For keywords, use hierarchical format with " > " separator (e.g., "Real Estate > Residential > Single Family", "Architecture > Interior > Kitchen", "Photography > Real Estate Photography > Wide Angle", "Features > Outdoor > Pool"):
- Start with broad categories (Real Estate, Architecture, Photography, Features)
- Progress to specific property types and spaces
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Real Estate > Residential > Single Family, Architecture > Interior > Kitchen, Photography > Real Estate Photography > Wide Angle, Features > Outdoor > Pool",
  "instructions": "editing suggestions or usage notes",
  "location": "neighborhood or area if identifiable"
}]]

-- Fine Art Photography Prompt
local fineArtPrompt = [[Please analyze this fine art photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable sources are present)

Focus on:
- Artistic vision and conceptual themes
- Art movement influences (surrealism, minimalism, expressionism)
- Emotional and psychological impact
- Symbolic and metaphorical content
- Creative techniques and experimental approaches
- Composition and visual elements
- Cultural and philosophical references
- Gallery and exhibition context
- Artist's statement and intention
- Contemporary or historical art contexts

For keywords, use hierarchical format with " > " separator (e.g., "Art > Fine Art > Photography", "Concepts > Abstract > Minimalism", "Photography > Artistic > Conceptual", "Movements > Contemporary > Postmodern"):
- Start with broad categories (Art, Concepts, Photography, Movements)
- Progress to specific styles and themes
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Art > Fine Art > Photography, Concepts > Abstract > Minimalism, Photography > Artistic > Conceptual, Movements > Contemporary > Postmodern",
  "instructions": "editing suggestions or usage notes",
  "location": "gallery or location if identifiable"
}]]

-- Black & White Photography Prompt
local blackWhitePrompt = [[Please analyze this black and white photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable settings are present)

Focus on:
- Tonal range and contrast characteristics
- Classic black and white photography techniques
- Mood and emotional impact of monochrome
- Texture and detail emphasis
- Lighting quality and shadow play
- Historical photography references
- Grain structure and film characteristics
- Composition without color distractions
- Timeless and classic aesthetic qualities
- Post-processing considerations for monochrome

For keywords, use hierarchical format with " > " separator (e.g., "Photography > Black and White > Classic", "Techniques > Monochrome > High Contrast", "Aesthetic > Timeless > Vintage", "Composition > Tonal > Shadow"):
- Start with broad categories (Photography, Techniques, Aesthetic, Composition)
- Progress to specific monochrome elements
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Photography > Black and White > Classic, Techniques > Monochrome > High Contrast, Aesthetic > Timeless > Vintage, Composition > Tonal > Shadow",
  "instructions": "editing suggestions or usage notes",
  "location": "setting or location if identifiable"
}]]

-- HDR/Long Exposure Photography Prompt
local hdrLongExposurePrompt = [[Please analyze this HDR/long exposure photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable locations are present)

Focus on:
- HDR technique and dynamic range capture
- Long exposure effects (motion blur, light trails, smooth water)
- Technical camera settings and equipment used
- Creative motion effects and time-based imagery
- Light painting and trail photography
- Water movement and cloud motion
- Traffic and urban light trails
- Astrophotography long exposures
- Post-processing techniques and tone mapping
- Equipment considerations (tripods, filters, remote triggers)

For keywords, use hierarchical format with " > " separator (e.g., "Photography > HDR > High Dynamic Range", "Techniques > Long Exposure > Motion Blur", "Effects > Light Trails > Traffic", "Equipment > Camera > Tripod"):
- Start with broad categories (Photography, Techniques, Effects, Equipment)
- Progress to specific methods and results
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Photography > HDR > High Dynamic Range, Techniques > Long Exposure > Motion Blur, Effects > Light Trails > Traffic, Equipment > Camera > Tripod",
  "instructions": "editing suggestions or usage notes",
  "location": "location name if identifiable"
}]]

-- Corporate/Business Photography Prompt
local corporatePrompt = [[Please analyze this corporate/business photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable business locations are present)

Focus on:
- Professional business environments and settings
- Corporate culture and team dynamics
- Business activities (meetings, presentations, collaboration)
- Office spaces and workplace design
- Professional attire and business formal presentation
- Technology and modern workplace tools
- Industry-specific contexts and environments
- Leadership and management scenarios
- Productivity and efficiency themes
- Brand representation and corporate identity

For keywords, use hierarchical format with " > " separator (e.g., "Business > Corporate > Office", "Photography > Corporate Photography > Professional", "Workplace > Team > Collaboration", "Industry > Technology > Modern"):
- Start with broad categories (Business, Photography, Workplace, Industry)
- Progress to specific contexts and activities
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Business > Corporate > Office, Photography > Corporate Photography > Professional, Workplace > Team > Collaboration, Industry > Technology > Modern",
  "instructions": "editing suggestions or usage notes",
  "location": "company or business location if identifiable"
}]]

-- Headshot/Professional Portrait Prompt
local headshotPrompt = [[Please analyze this headshot/professional portrait and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable studio or settings are present)

Focus on:
- Professional presentation and business appropriateness
- Studio lighting techniques and quality
- Background choice and professional context
- Facial expression and professional demeanor
- Wardrobe and styling for business contexts
- Industry-specific professional requirements
- LinkedIn and business profile usage
- Corporate branding and image consistency
- Retouching considerations and natural appearance
- Professional photography standards

Note: Do not attempt to identify specific individuals by name.

For keywords, use hierarchical format with " > " separator (e.g., "Photography > Portrait Photography > Headshot", "Business > Professional > Corporate", "Studio > Lighting > Professional", "Marketing > Branding > Professional Image"):
- Start with broad categories (Photography, Business, Studio, Marketing)
- Progress to specific professional contexts
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Photography > Portrait Photography > Headshot, Business > Professional > Corporate, Studio > Lighting > Professional, Marketing > Branding > Professional Image",
  "instructions": "editing suggestions or usage notes",
  "location": "studio or professional setting if identifiable"
}]]

-- Stock Photography Prompt
local stockPrompt = [[Please analyze this stock photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant hierarchical keywords organized from broad to specific categories
5. Special instructions for photo editing or usage
6. Location information (if identifiable generic locations are present)

Focus on:
- Commercial viability and broad market appeal
- Clear conceptual themes and universal concepts
- Versatile composition suitable for multiple uses
- Professional quality and technical excellence
- Target demographics and market segments
- Business and lifestyle applications
- Seasonal and trending topics
- Generic and widely applicable content
- Brand-safe and commercially appropriate subjects
- High-demand stock photography categories

For keywords, use hierarchical format with " > " separator (e.g., "Stock Photography > Commercial > Business", "Concepts > Lifestyle > Success", "Photography > Commercial Photography > Marketing", "Business > Concepts > Growth"):
- Start with broad categories (Stock Photography, Concepts, Photography, Business)
- Progress to specific commercial applications
- End with detailed descriptors
- Include 8-12 hierarchical keywords total

Please format your response as JSON with the following structure:
{
  "title": "short descriptive title",
  "caption": "brief caption here",
  "headline": "detailed headline/description here",
  "keywords": "Stock Photography > Commercial > Business, Concepts > Lifestyle > Success, Photography > Commercial Photography > Marketing, Business > Concepts > Growth",
  "instructions": "editing suggestions or usage notes",
  "location": "generic location type if identifiable"
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
    },
    {
        name = "Astrophotography",
        description = "Celestial objects, astronomical events, and technical astrophotography details",
        prompt = astrophotographyPrompt
    },
    {
        name = "Concert & Music",
        description = "Live music performances, stage lighting, and musical event documentation",
        prompt = concertPrompt
    },
    {
        name = "Documentary Photography",
        description = "Social themes, cultural documentation, and photojournalistic storytelling",
        prompt = documentaryPrompt
    },
    {
        name = "Pet & Animal Photography",
        description = "Domestic animals, pet behavior, and human-animal relationships",
        prompt = petPrompt
    },
    {
        name = "Medical & Scientific",
        description = "Clinical documentation, scientific research, and educational imagery",
        prompt = medicalPrompt
    },
    {
        name = "Real Estate Photography",
        description = "Property documentation, interior spaces, and architectural features",
        prompt = realEstatePrompt
    },
    {
        name = "Fine Art Photography",
        description = "Artistic vision, conceptual themes, and gallery-worthy artistic expression",
        prompt = fineArtPrompt
    },
    {
        name = "Black & White Photography",
        description = "Monochrome aesthetics, tonal range, and classic photography techniques",
        prompt = blackWhitePrompt
    },
    {
        name = "HDR & Long Exposure",
        description = "High dynamic range, motion effects, and technical creative photography",
        prompt = hdrLongExposurePrompt
    },
    {
        name = "Corporate & Business",
        description = "Professional environments, business activities, and corporate imagery",
        prompt = corporatePrompt
    },
    {
        name = "Headshot & Professional Portrait",
        description = "Professional portraits, business headshots, and corporate branding imagery",
        prompt = headshotPrompt
    },
    {
        name = "Stock Photography",
        description = "Commercial viability, broad market appeal, and versatile business imagery",
        prompt = stockPrompt
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
            -- Create a copy of the preset with language and hierarchical keyword instructions added
            local enhancedPrompt = addLanguageInstruction(preset.prompt)
            enhancedPrompt = addHierarchicalKeywordInstruction(enhancedPrompt)
            
            local enhancedPreset = {
                name = preset.name,
                description = preset.description,
                prompt = enhancedPrompt
            }
            return enhancedPreset
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
