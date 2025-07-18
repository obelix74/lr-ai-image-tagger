--[[----------------------------------------------------------------------------

 AI Image Tagger
 Copyright 2024 Anand Kumar Sankaran
 Updated for Lightroom Classic 2024 and Gemini AI

--------------------------------------------------------------------------------

AiTaggerMenuItem.lua

------------------------------------------------------------------------------]]

local LrApplication = import "LrApplication"
local LrPrefs = import "LrPrefs"
local LrTasks = import "LrTasks"
local LrHttp = import "LrHttp"
local LrDate = import "LrDate"
local LrColor = import "LrColor"
local LrStringUtils = import "LrStringUtils"
local LrFunctionContext = import "LrFunctionContext"
local LrProgressScope = import "LrProgressScope"
local LrDialogs = import "LrDialogs"
local LrBinding = import "LrBinding"
local LrView = import "LrView"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local bind = LrView.bind
local share = LrView.share

--------------------------------------------------------------------------------

local inspect = require "inspect"
require "Logger"
require "GeminiAPI"

--------------------------------------------------------------------------------

local prefs = LrPrefs.prefsForPlugin()

-- Collection management constants
local KEYWORD_COLLECTIONS = {
	["Landscapes"] = {"landscape", "nature", "outdoor", "mountain", "ocean", "forest", "desert", "valley", "lake", "river"},
	["People"] = {"person", "people", "portrait", "face", "family", "child", "baby", "man", "woman"},
	["Animals"] = {"animal", "dog", "cat", "bird", "horse", "wildlife", "pet", "farm", "zoo"},
	["Architecture"] = {"building", "house", "church", "bridge", "tower", "architecture", "urban", "city"},
	["Food"] = {"food", "meal", "restaurant", "cooking", "kitchen", "fruit", "vegetable", "drink"},
	["Events"] = {"wedding", "party", "birthday", "celebration", "festival", "concert", "graduation"},
	["Sports"] = {"sport", "football", "basketball", "tennis", "running", "swimming", "cycling", "golf"},
	["Travel"] = {"travel", "vacation", "tourist", "hotel", "airport", "train", "car", "road"}
}

local LOCATION_COLLECTIONS = {
	["National Parks"] = {"national park", "yosemite", "yellowstone", "grand canyon", "zion"},
	["Cities"] = {"city", "urban", "downtown", "street", "skyline", "new york", "san francisco", "los angeles"},
	["Landmarks"] = {"landmark", "monument", "statue", "historic", "famous", "tower", "bridge"},
	["Indoor"] = {"indoor", "inside", "room", "house", "building", "interior"},
	["Outdoor"] = {"outdoor", "outside", "garden", "park", "field", "forest"},
	["Beach"] = {"beach", "ocean", "sea", "sand", "coast", "shore", "wave"},
	["Mountains"] = {"mountain", "hill", "peak", "summit", "alpine", "hiking", "climbing"}
}

local propPhotos = "photos"
local propCurrentPhotoIndex = "currentPhotoIndex"
local propCurrentPhotoName = "currentPhotoName"
local propTotalPhotos = "totalPhotos"
local propStartTime = "startTime"
local propElapsedTime = "elapsedTime"
local propConsumedTime = "consumedTime"
local propMaxKeywords = "maxKeywords"
local propTitle = "title"
local propCaption = "caption"
local propHeadline = "headline"
local propInstructions = "instructions"
local propLocation = "location"

local function propKeywordTitle( i )
	return string.format( "keywordTitle%d", i )
end
local function propKeywordSelected( i )
	return string.format( "keywordSelected%d", i )
end

--------------------------------------------------------------------------------

-- Collection Management Functions

-- Store AI metadata using standard properties
local function storeAIMetadata(photo, confidence, categories, processDate)
	logger:tracef("storeAIMetadata called for photo %s with confidence %s", 
		photo:getFormattedMetadata("fileName"), tostring(confidence))
	
	-- Store confidence in a custom field or keyword instead of overwriting instructions
	-- The instructions field should preserve the AI-generated content in the user's language
	
	-- Store categories as a special keyword prefix
	if categories and #categories > 0 then
		logger:tracef("Adding %d AI category keywords", #categories)
		local catalog = LrApplication.activeCatalog()
		for _, category in ipairs(categories) do
			local keywordName = "AI:" .. category
			logger:tracef("Creating keyword: %s", keywordName)
			local keyword = catalog:createKeyword(keywordName, {}, false, nil, true)
			photo:addKeyword(keyword)
		end
	else
		logger:tracef("No categories provided for AI keywords")
	end
end

-- Create or get collection set for AI tagged photos
local function getOrCreateAICollectionSet()
	local catalog = LrApplication.activeCatalog()
	local collectionSet = nil
	
	-- Look for existing AI collection set
	local allCollections = catalog:getChildCollectionSets()
	for _, set in ipairs(allCollections) do
		if set:getName() == "Gemini AI Tagged" then
			collectionSet = set
			break
		end
	end
	
	-- Create if doesn't exist
	if not collectionSet then
		collectionSet = catalog:createCollectionSet("Gemini AI Tagged", nil, true)
		logger:info("Created AI collection set: Gemini AI Tagged")
	end
	
	return collectionSet
end

-- Create or get a collection within the AI collection set
local function getOrCreateCollection(name, parent)
	local catalog = LrApplication.activeCatalog()
	
	-- Look for existing collection
	local collections = parent:getChildCollections()
	for _, collection in ipairs(collections) do
		if collection:getName() == name then
			return collection
		end
	end
	
	-- Create new collection
	local collection = catalog:createCollection(name, parent, true)
	logger:infof("Created collection: %s", name)
	
	-- Force refresh to ensure collection info is available
	LrTasks.yield()
	
	return collection
end

-- Determine which collections a photo should belong to based on keywords
local function determinePhotoCollections(keywords, scheme)
	local collections = {}
	
	if scheme == "Content-Based" then
		for collectionName, collectionKeywords in pairs(KEYWORD_COLLECTIONS) do
			for _, keyword in ipairs(keywords) do
				for _, collectionKeyword in ipairs(collectionKeywords) do
					if string.lower(keyword):find(string.lower(collectionKeyword)) then
						table.insert(collections, collectionName)
						break
					end
				end
			end
		end
	elseif scheme == "Location-Based" then
		for collectionName, collectionKeywords in pairs(LOCATION_COLLECTIONS) do
			for _, keyword in ipairs(keywords) do
				for _, collectionKeyword in ipairs(collectionKeywords) do
					if string.lower(keyword):find(string.lower(collectionKeyword)) then
						table.insert(collections, collectionName)
						break
					end
				end
			end
		end
	end
	
	-- Remove duplicates
	local uniqueCollections = {}
	local seen = {}
	for _, collection in ipairs(collections) do
		if not seen[collection] then
			table.insert(uniqueCollections, collection)
			seen[collection] = true
		end
	end
	
	return uniqueCollections
end

-- Create auto collections for processed photos
local function createAutoCollections(processedPhotos)
	if not prefs.createAutoCollections then
		return
	end
	
	LrTasks.startAsyncTask(function()
		logger:info("Creating auto collections for AI tagged photos...")
		
		local catalog = LrApplication.activeCatalog()
		local aiCollectionSet = nil
		local schemeSet = nil
		local qualitySet = nil
			
		-- Step 1: Create collection sets first
		catalog:withWriteAccessDo("Create Collection Sets", function()
			aiCollectionSet = getOrCreateAICollectionSet()
			if prefs.createAutoCollections then
				local scheme = prefs.collectionScheme or "Content-Based"
				schemeSet = catalog:createCollectionSet(scheme, aiCollectionSet, true)
				qualitySet = catalog:createCollectionSet("Quality-Based", aiCollectionSet, true)
				logger:infof("Created collection sets: %s, Quality-Based", scheme)
			end
		end)
		
		-- Step 2: Create content-based collections
		if prefs.createAutoCollections and schemeSet then
			local scheme = prefs.collectionScheme or "Content-Based"
			
			-- Group photos by their determined collections
			local photoGroups = {}
			
			for _, photoData in ipairs(processedPhotos) do
				local keywords = {}
				if photoData.keywords then
					for _, keywordData in ipairs(photoData.keywords) do
						if keywordData.selected then
							table.insert(keywords, keywordData.title or keywordData.description)
						end
					end
				end
				
				local photoCollections = determinePhotoCollections(keywords, scheme)
				
				for _, collectionName in ipairs(photoCollections) do
					photoGroups[collectionName] = photoGroups[collectionName] or {}
					table.insert(photoGroups[collectionName], photoData.photo)
				end
			end
			
			-- Create collections and add photos in separate write access
			catalog:withWriteAccessDo("Create Content Collections", function()
				for collectionName, photos in pairs(photoGroups) do
					if #photos > 0 then
						local collection = catalog:createCollection(collectionName, schemeSet, true)
						collection:addPhotos(photos)
						logger:infof("Added %d photos to collection: %s", #photos, collectionName)
					end
				end
			end)
		end
		
		-- Step 3: Create quality-based collections
		if prefs.createAutoCollections and qualitySet then
			local highConfidence = {}
			local mediumConfidence = {}
			local lowConfidence = {}
			
			for _, photoData in ipairs(processedPhotos) do
				local confidence = photoData.confidence or 0.5
				
				if confidence >= 0.9 then
					table.insert(highConfidence, photoData.photo)
				elseif confidence >= 0.7 then
					table.insert(mediumConfidence, photoData.photo)
				else
					table.insert(lowConfidence, photoData.photo)
				end
			end
			
			-- Create quality collections in separate write access
			catalog:withWriteAccessDo("Create Quality Collections", function()
				if #highConfidence > 0 then
					local collection = catalog:createCollection("High Confidence (>90%)", qualitySet, true)
					collection:addPhotos(highConfidence)
					logger:infof("Added %d photos to High Confidence collection", #highConfidence)
				end
				
				if #mediumConfidence > 0 then
					local collection = catalog:createCollection("Medium Confidence (70-90%)", qualitySet, true)
					collection:addPhotos(mediumConfidence)
					logger:infof("Added %d photos to Medium Confidence collection", #mediumConfidence)
				end
				
				if #lowConfidence > 0 then
					local collection = catalog:createCollection("Needs Review (<70%)", qualitySet, true)
					collection:addPhotos(lowConfidence)
					logger:infof("Added %d photos to Needs Review collection", #lowConfidence)
				end
			end)
		end
		
		
		logger:info("Auto collections creation completed")
	end)
end

--------------------------------------------------------------------------------

-- save photo from propertyTable[ propXXX ] to propertyTable.photos[ i ]
local function savePhoto( propertyTable, index )
	-- Skip saving if index is 0 (no photo selected) or out of range
	if index <= 0 or index > #propertyTable[ propPhotos ] then
		logger:tracef( "savePhoto: skipping invalid index %d (valid range: 1-%d)", index, #propertyTable[ propPhotos ] )
		return
	end

	local photo = propertyTable[ propPhotos ][ index ]
	if photo ~= nil then
		local keywords = photo.keywords or { }
		for i, keyword in ipairs( keywords ) do
			keyword.selected = propertyTable[ propKeywordSelected( i ) ]
		end

		-- Save all metadata fields
		photo.title = propertyTable[ propTitle ]
		photo.caption = propertyTable[ propCaption ]
		photo.headline = propertyTable[ propHeadline ]
		photo.instructions = propertyTable[ propInstructions ]
		photo.location = propertyTable[ propLocation ]
	end
end

-- load photo from propertyTable.photos[ i ] to propertyTable[ propXXX ]
local function loadPhoto( propertyTable, index )
	-- Skip loading if index is invalid or out of range
	if index <= 0 or index > #propertyTable[ propPhotos ] then
		logger:errorf( "loadPhoto: invalid index %d (valid range: 1-%d)", index, #propertyTable[ propPhotos ] )
		return
	end

	local photo = propertyTable[ propPhotos ][ index ]
	if photo == nil then
		logger:errorf( "loadPhoto: photo at index %d is nil", index )
		return
	end

	local keywords = photo.keywords or { }
	for i = 1, prefs.maxKeywords do
		local keyword = keywords[ i ] or { description = nil, selected = false }
		propertyTable[ propKeywordTitle( i ) ] = keyword.description
		propertyTable[ propKeywordSelected( i ) ] = keyword.selected
	end

	-- Load all metadata fields
	propertyTable[ propTitle ] = photo.title or ""
	propertyTable[ propCaption ] = photo.caption or ""
	propertyTable[ propHeadline ] = photo.headline or ""
	propertyTable[ propInstructions ] = photo.instructions or ""
	propertyTable[ propLocation ] = photo.location or ""
end

-- select photo (i.e. move from index X to Y)
local function selectPhoto( propertyTable, newIndex )
	local oldIndex = propertyTable[ propCurrentPhotoIndex ]
	if oldIndex ~= newIndex then
		savePhoto( propertyTable, oldIndex )
	end

	if newIndex > 0 and newIndex <= #propertyTable[ propPhotos ] then
		loadPhoto( propertyTable, newIndex )
		propertyTable[ propCurrentPhotoIndex ] = newIndex
	else
		logger:errorf( "selectPhoto failed: index %d out of range (1-%d)", newIndex, #propertyTable[ propPhotos ] )
	end
end

-- apply the selected keywords and all metadata to the photo
local function applyMetadataToPhoto( photo, keywords, title, caption, headline, instructions, location, confidence )
	-- Helper function to safely set metadata
	local function safeSetMetadata( fieldName, value, description )
		local success, error = pcall( function()
			photo:setRawMetadata( fieldName, value )
		end )
		if success then
		else
			logger:errorf( "failed to set %s (%s): %s", description, fieldName, tostring(error) )
		end
		return success
	end

	local catalog = photo.catalog
	catalog:withWriteAccessDo(
		LOC( "$$$/AiTagger/ActionName=Apply Metadata " ),
		function()
			local function createDecoratedKeyword( name, decoration, value )
				local parent = nil
				if decoration == AiTaggerConstants.decorateKeywordParent then
					parent = catalog:createKeyword( value, nil, true, nil, true )
					if parent == nil then
						logger:errorf( "failed to add parent keyword %s", value )
						return nil
					end
				end
				if decoration == AiTaggerConstants.decorateKeywordPrefix then
					name = string.format( "%s %s", value, name )
				elseif decoration == AiTaggerConstants.decorateKeywordSuffix then
					name = string.format( "%s %s", name, value )
				else
					 -- AiTaggerConstants.decorateKeywordAsIs or decorateKeywordParent, do nothing
				end
				return catalog:createKeyword( name, nil, true, parent, true )
			end

			-- Apply keywords to Lightroom Keywords
			local selectedKeywords = {}
			for _, keyword in ipairs( keywords ) do
				if keyword.selected then
					-- Add to Lightroom Keywords
					local keywordObj = createDecoratedKeyword( keyword.description, prefs.decorateKeyword, prefs.decorateKeywordValue )
					if keywordObj then
						photo:addKeyword( keywordObj )
					else
						logger:errorf( "failed to add keyword %s", keyword.description )
					end

					-- Collect for IPTC Keywords (use original description, not decorated)
					table.insert( selectedKeywords, keyword.description )
				end
			end

			-- Save keywords to IPTC Keywords field as well
			if prefs.saveKeywordsToIptc and #selectedKeywords > 0 then
				-- Note: Lightroom doesn't expose a direct IPTC keywords field via setRawMetadata
				-- Keywords are automatically included in IPTC when exporting if they're in Lightroom Keywords
				-- This is a limitation of the Lightroom SDK
				logger:tracef( "IPTC keywords: Lightroom automatically includes keywords in IPTC on export. Selected keywords: %s",
					table.concat( selectedKeywords, ", " ) )
			else
				logger:tracef( "skipping IPTC keywords: enabled=%s, count=%d", tostring(prefs.saveKeywordsToIptc), #selectedKeywords )
			end

			-- Apply IPTC metadata using correct Lightroom field names
			logger:tracef( "IPTC preferences: title=%s, caption=%s, headline=%s, instructions=%s, copyright=%s, location=%s",
				tostring(prefs.saveTitleToIptc), tostring(prefs.saveCaptionToIptc), tostring(prefs.saveHeadlineToIptc),
				tostring(prefs.saveInstructionsToIptc), tostring(prefs.saveCopyrightToIptc),
				tostring(prefs.saveLocationToIptc) )

			if prefs.saveTitleToIptc and title and title ~= "" then
				safeSetMetadata( "title", title, "IPTC title" )
			else
				logger:tracef( "skipping IPTC title: enabled=%s, title='%s'", tostring(prefs.saveTitleToIptc), title or "nil" )
			end

			if prefs.saveCaptionToIptc and caption and caption ~= "" then
				safeSetMetadata( "caption", caption, "IPTC caption" )
			else
				logger:tracef( "skipping IPTC caption: enabled=%s, caption='%s'", tostring(prefs.saveCaptionToIptc), caption or "nil" )
			end

			if prefs.saveHeadlineToIptc and headline and headline ~= "" then
				safeSetMetadata( "headline", headline, "IPTC headline" )
			else
				logger:tracef( "skipping IPTC headline: enabled=%s, headline='%s'", tostring(prefs.saveHeadlineToIptc), headline or "nil" )
			end

			if prefs.saveInstructionsToIptc and instructions and instructions ~= "" then
				safeSetMetadata( "instructions", instructions, "IPTC instructions" )
			end


			if prefs.saveLocationToIptc and location and location ~= "" then
				-- Try different location fields that are known to work in Lightroom
				safeSetMetadata( "location", location, "IPTC location" )
				safeSetMetadata( "city", location, "IPTC city" )
			end
			
			-- Store AI metadata for collection management
			if confidence then
				storeAIMetadata( photo, confidence, selectedKeywords, LrDate.currentTime() )
			end
		end,
		{ timeout = 5 }
	)
end

-- Export analysis results to CSV
local function exportResults( propertyTable )
	local photos = propertyTable[ propPhotos ]
	if not photos or #photos == 0 then
		LrDialogs.message( LOC( "$$$/AiTagger/Export/NoResults=No Results" ), LOC( "$$$/AiTagger/Export/NoResultsMessage=No analysis results to export." ), "info" )
		return
	end

	local fileName = LrDialogs.runSavePanel( {
		title = LOC( "$$$/AiTagger/Export/Title=Export Analysis Results" ),
		label = LOC( "$$$/AiTagger/Export/SaveAs=Save as:" ),
		requiredFileType = "csv",
		initialDirectory = LrPathUtils.getStandardFilePath( "desktop" ),
		initialFileName = "aiimagetagger_results_" .. LrDate.timeToUserFormat( LrDate.currentTime(), "%Y%m%d_%H%M%S" ) .. ".csv"
	} )

	if fileName then
		local file = io.open( fileName, "w" )
		if file then
			-- Write CSV header
			file:write( LOC( "$$$/AiTagger/Export/CSVHeader=Filename,Title,Caption,Headline,Keywords,Instructions,Location,Analysis Time (sec)" ) .. "\n" )

			-- Write data for each photo
			for _, photoData in ipairs( photos ) do
				local photo = photoData.photo
				local filename = photo:getFormattedMetadata( "fileName" ) or ""
				local title = (photoData.title or ""):gsub( '"', '""' ) -- Escape quotes
				local caption = (photoData.caption or ""):gsub( '"', '""' )
				local headline = (photoData.headline or ""):gsub( '"', '""' )
				local instructions = (photoData.instructions or ""):gsub( '"', '""' )
				local location = (photoData.location or ""):gsub( '"', '""' )
				local elapsed = photoData.elapsed or 0

				-- Collect selected keywords
				local keywords = {}
				if photoData.keywords then
					for _, keyword in ipairs( photoData.keywords ) do
						if keyword.selected then
							table.insert( keywords, keyword.description )
						end
					end
				end
				local keywordStr = table.concat( keywords, "; " ):gsub( '"', '""' )

				file:write( string.format( '"%s","%s","%s","%s","%s","%s","%s",%.3f\n',
					filename, title, caption, headline, keywordStr, instructions, location, elapsed ) )
			end

			file:close()
			LrDialogs.message( LOC( "$$$/AiTagger/Export/Complete=Export Complete" ), LOC( "$$$/AiTagger/Export/CompleteMessage=Analysis results exported to:\n" ) .. fileName, "info" )
		else
			LrDialogs.message( LOC( "$$$/AiTagger/Export/Failed=Export Failed" ), LOC( "$$$/AiTagger/Export/FailedMessage=Could not create file:\n" ) .. fileName, "error" )
		end
	end
end

local function showResponse( propertyTable )

	local f = LrView.osFactory()

	-- create keywords array
	local keywords = { }
	for i = 1, prefs.maxKeywords do
		local propTitle = propKeywordTitle( i )
		local propSelected = propKeywordSelected( i )
		table.insert( keywords,
			f:row {
				f:checkbox {
					visible = LrBinding.keyIsNotNil( propTitle ),
					title = bind { key = propTitle },
					value = bind { key = propSelected },
					width = 300,
				},
			}
		)
	end



	propertyTable:addObserver( propPhotos,
		function( propertyTable, key, value )
			if #value > 0 and propertyTable[ propCurrentPhotoIndex ] == 0 then
				selectPhoto( propertyTable, 1 )
			end
		end
	)

	propertyTable:addObserver( propCurrentPhotoIndex,
		function( propertyTable, key, value )
			LrTasks.startAsyncTask(
				function()
					local photo = propertyTable[ propPhotos ][ value ].photo
					propertyTable[ propCurrentPhotoName ] = photo:getFormattedMetadata( "fileName" )
				end
			)
		end
	)

	local contents = f:column {
		bind_to_object = propertyTable,
		spacing = f:dialog_spacing(),
		fill_horizontal = 1,
		place_horizontal = 0.5,
		width = 900,
		f:column {
			fill_horizontal = 1,
			place_horizontal = 0.5,
			f:row {
				f:push_button {
					title = LOC( "$$$/AiTagger/PrevPhoto=^U+25C0" ),
					fill_horizontal = 0.25,
					place_vertical = 0.5,
					enabled = bind {
						key = propCurrentPhotoIndex,
						transform = function( value, fromTable )
							local hasPrev = (value or 0) > 1
							return hasPrev
						end,
					},
					action = function( btn )
						local currentIndex = propertyTable[ propCurrentPhotoIndex ]
						local newIndex = currentIndex - 1
						selectPhoto( propertyTable, newIndex )
					end,
				},
				f:catalog_photo {
					visible = LrBinding.keyIsNot( propCurrentPhotoIndex, 0 ),
					photo = bind {
						key = propCurrentPhotoIndex,
						transform = function( value, fromTable )
							if value > 0 then
								return propertyTable[ propPhotos ][ value ].photo
							end
							return nil
						end,
					},
					width = 400,
					height = 300,
					fill_horizontal = 0.5,
					place_horizontal = 0.5,
					frame_width = 0,
					frame_color = LrColor(), -- alpha = 0
					background_color = LrColor(), -- alpha = 0
				},
				f:push_button {
					title = LOC( "$$$/AiTagger/NextPhoto=^U+25B6" ),
					fill_horizontal = 0.25,
					place_vertical = 0.5,
					enabled = bind {
						keys = { propCurrentPhotoIndex, propPhotos },
						operation = function( binder, values, fromTable )
							local i = values[ propCurrentPhotoIndex ] or 0
							local photos = values[ propPhotos ] or {}
							local hasNext = photos[ i + 1 ] ~= nil
							return hasNext
						end,
					},
					action = function( btn )
						local currentIndex = propertyTable[ propCurrentPhotoIndex ]
						local newIndex = currentIndex + 1
						logger:tracef( "next photo: current=%d, new=%d, total=%d", currentIndex, newIndex, #propertyTable[ propPhotos ] )
						selectPhoto( propertyTable, newIndex )
					end,
				},
			},
			f:static_text {
				visible = LrBinding.keyIsNot( propCurrentPhotoIndex, 0 ),
				title = bind {
					keys = { propCurrentPhotoIndex, propCurrentPhotoName, propPhotos },
					operation = function( binder, values, fromTable )
						return LOC( "$$$/AiTagger/PhotoXofY=Photo ^1 of ^2: ^3 (^4 sec)",
							LrStringUtils.numberToStringWithSeparators( values[ propCurrentPhotoIndex ], 0 ),
							LrStringUtils.numberToStringWithSeparators( #values[ propPhotos ], 0 ),
							values[ propCurrentPhotoName ],
							LrStringUtils.numberToStringWithSeparators( values[ propPhotos ][ values[ propCurrentPhotoIndex ] ].elapsed, 2 ) )
					end,
				},
				fill_horizontal = 1,
				alignment = "center"
			},
			f:static_text {
				title = bind {
					key = propPhotos,
					transform = function( value, fromTable )
						local numPhotos = #value
						local remPhotos = propertyTable[ propTotalPhotos ] - numPhotos
						local consumedTime = propertyTable[ propConsumedTime ]
						local elapsedTime = propertyTable[ propElapsedTime ]
						if remPhotos > 0 then
							if #value > 0 then
								-- use elapsedTime rather than consumedTime to factor in parallelization
								local remTime = math.ceil( elapsedTime / numPhotos * remPhotos )
								return LOC( "$$$/AiTagger/PhotosRemaining=^1 photos to analyze, estimated completion in ^2 sec (^3 sec elapsed)",
									LrStringUtils.numberToStringWithSeparators( remPhotos, 0 ),
									LrStringUtils.numberToStringWithSeparators( remTime, 0 ),
									LrStringUtils.numberToStringWithSeparators( elapsedTime, 2 ) )
							else
								return LOC( "$$$/AiTagger/PhotosRemaining=^1 photos to analyze",
									LrStringUtils.numberToStringWithSeparators( remPhotos, 0 ) )
							end
						else
							return LOC( "$$$/AiTagger/PhotosRemaining=^1 photos analyzed in ^2 sec (^3 sec elapsed)",
								LrStringUtils.numberToStringWithSeparators( numPhotos, 0 ),
								LrStringUtils.numberToStringWithSeparators( consumedTime, 2 ),
								LrStringUtils.numberToStringWithSeparators( elapsedTime, 2 ) )
						end
					end,
				},
				fill_horizontal = 1,
				alignment = "center"
			},
		},
		f:row {
			f:column {
				fill_horizontal = 0.5,
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogTitleTitle=Title" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propTitle },
						fill_horizontal = 1,
						height_in_lines = 1,
						width = 425,
					},
				},
				f:spacer { height = 8 },
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogKeywordsTitle=Keywords" ),
					font = "<system/bold>",
					f:row {
						place = "overlapping",
						f:column {
							f:static_text {
								visible = LrBinding.keyIsNil( propKeywordTitle( 1 ) ),
								title = LOC( "$$$/AiTagger/NoKeywords=None" ),
								fill_horizontal = 1,
							},
						},
						f:column( keywords ),
					},
					f:row {
						visible = LrBinding.keyIsNotNil( propKeywordTitle( 1 ) ),
						f:push_button {
							title = LOC( "$$$/AiTagger/SelectAllKeywords=Select All" ),
							action = function()
								for i = 1, prefs.maxKeywords do
									if propertyTable[ propKeywordTitle( i ) ] then
										propertyTable[ propKeywordSelected( i ) ] = true
									end
								end
							end,
						},
						f:push_button {
							title = LOC( "$$$/AiTagger/DeselectAllKeywords=Deselect All" ),
							action = function()
								for i = 1, prefs.maxKeywords do
									if propertyTable[ propKeywordTitle( i ) ] then
										propertyTable[ propKeywordSelected( i ) ] = false
									end
								end
							end,
						},
					},
				},
			},
			f:spacer { width = 8 },
			f:column {
				fill_horizontal = 0.5,
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogCaptionTitle=Caption" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propCaption },
						fill_horizontal = 1,
						height_in_lines = 2,
						width = 425,
					},
				},
				f:spacer { height = 8 },
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogHeadlineTitle=Headline" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propHeadline },
						fill_horizontal = 1,
						height_in_lines = 4,
						width = 425,
					},
				},
				f:spacer { height = 8 },
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogInstructionsTitle=Instructions" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propInstructions },
						fill_horizontal = 1,
						height_in_lines = 3,
						width = 425,
					},
				},
				f:spacer { height = 8 },
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogLocationTitle=Location" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propLocation },
						fill_horizontal = 1,
						height_in_lines = 2,
						width = 425,
					},
				},
			},
		},
		f:row {
			fill_horizontal = 1,
			f:push_button {
				enabled = LrBinding.keyIsNot( propCurrentPhotoIndex, 0 ),
				title = LOC( "$$$/AiTagger/ResultsDialogApply=Apply" ),
				place_horizontal = 1,
				action = function()
					LrTasks.startAsyncTask(
						function()
							savePhoto( propertyTable, propertyTable[ propCurrentPhotoIndex ])
							local photo = propertyTable[ propPhotos ][ propertyTable[ propCurrentPhotoIndex ] ]
							applyMetadataToPhoto( photo.photo, photo.keywords, photo.title, photo.caption, photo.headline, photo.instructions, photo.location, photo.confidence )
						end
					)
				end,
			},
			f:push_button {
				enabled = LrBinding.keyIsNot( propCurrentPhotoIndex, 0 ),
				title = LOC( "$$$/AiTagger/ResultsDialogExport=Export Results" ),
				place_horizontal = 1,
				action = function()
					LrTasks.startAsyncTask(
						function()
							savePhoto( propertyTable, propertyTable[ propCurrentPhotoIndex ])
							exportResults( propertyTable )
						end
					)
				end,
			}
		},
	}
	local results = LrDialogs.presentModalDialog {
		title = LOC( "$$$/AiTagger/ResultsDialogTitle=AiTagger: Gemini AI Results" ),
		resizable = true,
		contents = contents,
		cancelVerb = LOC( "$$$/AiTagger/ResultsDialogCancel=Cancel" ),
		actionVerb = LOC( "$$$/AiTagger/ResultsDialogApplyAll=Apply All" ),
	}
	
	-- Handle the dialog result
	if results == "ok" then
		-- User clicked "Apply All" button (the default action)
		LrTasks.startAsyncTask(
			function()
				savePhoto( propertyTable, propertyTable[ propCurrentPhotoIndex ])
				for _, photo in ipairs( propertyTable[ propPhotos ] ) do
					applyMetadataToPhoto( photo.photo, photo.keywords, photo.title, photo.caption, photo.headline, photo.instructions, photo.location, photo.confidence )
				end
				
				-- Create auto collections after applying all metadata (in separate task to avoid write access conflicts)
				LrTasks.startAsyncTask(function()
					LrTasks.sleep(0.5) -- Small delay to ensure all metadata writes are complete
					createAutoCollections( propertyTable[ propPhotos ] )
				end)
			end
		)
	end
end

local function AiTagger()
	LrFunctionContext.postAsyncTaskWithContext( "analyzing photos",
		function( context )
			LrDialogs.attachErrorDialogToFunctionContext( context )
			local catalog = LrApplication.activeCatalog()

			-- Check Gemini API key
			if not GeminiAPI.hasApiKey() then
				logger:errorf( "Gemini API key not configured" )
				local errorMsg = "Gemini API key not configured.\n\nPlease check:\n• Gemini API key is properly configured in plugin settings\n• API key has necessary permissions"
				LrDialogs.message( LOC( "$$$/AiTagger/AuthFailed=Gemini API key not configured" ), errorMsg, "critical" )
			else
				local propertyTable = LrBinding.makePropertyTable( context )
				local photos = catalog:getTargetPhotos()

				propertyTable[ propPhotos ] = { }
				propertyTable[ propCurrentPhotoIndex ] = 0
				propertyTable[ propTotalPhotos ] = #photos
				propertyTable[ propStartTime ] = LrDate.currentTime()
				propertyTable[ propElapsedTime ] = 0 -- elapsed wall time
				propertyTable[ propConsumedTime ] = 0 -- consumed CPU time
				propertyTable[ propTitle ] = ""
				propertyTable[ propCaption ] = ""
				propertyTable[ propHeadline ] = ""
				propertyTable[ propInstructions ] = ""
				propertyTable[ propLocation ] = ""

				local progressScope = LrProgressScope {
					title = LOC( "$$$/AiTagger/ProgressScopeTitle=Analyzing Photos" ),
					functionContext = context
				}
				progressScope:setCancelable( true )

				-- show the progress dialog, as an async task (will be triggered after analysis completes)
				local inDialog = true

				-- First phase: Collect all thumbnails
				local thumbnailData = { } -- Store thumbnail data for processing
				local processingErrors = { } -- Collect errors instead of showing modal dialogs
				local thumbnailsPending = #photos
				logger:tracef( "begin collecting %d thumbnails", #photos )

				-- Set initial progress message
				progressScope:setCaption( LOC( "$$$/AiTagger/ProgressStarting=Collecting thumbnails for ^1 photos...", #photos ) )
				progressScope:setPortionComplete( 0, #photos )
				
				for i, photo in ipairs( photos ) do
					if progressScope:isCanceled() or progressScope:isDone() then
						break
					end

					-- Update the progress bar
					local fileName = photo:getFormattedMetadata( "fileName" )
					progressScope:setCaption( LOC( "$$$/AiTagger/ProgressCaption=Preparing ^1 (^2 of ^3)", fileName, i, #photos ) )
					progressScope:setPortionComplete( (i-1), #photos )

					-- Request thumbnail in non-yielding context
					photo:requestJpegThumbnail( prefs.thumbnailWidth, prefs.thumbnailHeight,
						function( jpegData, errorMsg )
							if jpegData then
								-- Store thumbnail data for later processing
								table.insert( thumbnailData, {
									photo = photo,
									jpegData = jpegData,
									fileName = fileName,
									index = i
								})
							else
								-- Collect thumbnail error
								table.insert( processingErrors, { fileName = fileName, message = errorMsg or "Failed to generate thumbnail", type = "thumbnail" } )
							end
							
							thumbnailsPending = thumbnailsPending - 1
						end
					)
				end

				-- Wait for all thumbnails to be collected
				while thumbnailsPending > 0 and not (progressScope:isCanceled() or progressScope:isDone()) do
					LrTasks.sleep( 0.1 )
				end

				-- Second phase: Process thumbnails with AI analysis
				local runningTasks = 0
				local totalThumbnails = #thumbnailData
				logger:tracef( "begin analyzing %d thumbnails", totalThumbnails )

				progressScope:setCaption( LOC( "$$$/AiTagger/ProgressStarting=Starting AI analysis of ^1 photos...", totalThumbnails ) )
				progressScope:setPortionComplete( 0, totalThumbnails )
				
				for i, thumbnailInfo in ipairs( thumbnailData ) do
					if progressScope:isCanceled() or progressScope:isDone() then
						break
					end

					local photo = thumbnailInfo.photo
					local jpegData = thumbnailInfo.jpegData
					local fileName = thumbnailInfo.fileName
					local originalIndex = thumbnailInfo.index

					local function trace( msg, ... )
						logger:tracef( "[%d | %d | %s] %s", totalThumbnails, i, fileName, string.format( msg, ... ) )
					end

					while ( runningTasks >= prefs.maxTasks ) and not ( progressScope:isCanceled() or progressScope:isDone() ) do
						LrTasks.sleep( 0.2 )
					end
					runningTasks = runningTasks + 1

					-- Process in async task context where yielding is allowed
					LrTasks.startAsyncTask(
						function()
							LrFunctionContext.callWithContext( "aiAnalysis", function( context )
								trace( "analyzing thumbnail (%s bytes)", LrStringUtils.numberToStringWithSeparators( #jpegData, 0 ) )

								-- Update progress to show AI analysis in progress
								if not (progressScope:isCanceled() or progressScope:isDone()) then
									progressScope:setCaption( LOC( "$$$/AiTagger/ProgressAnalyzing=Analyzing with AI: ^1 (^2 of ^3)", fileName, i, totalThumbnails ) )
								end

								local start = LrDate.currentTime()
								local result = GeminiAPI.analyze( fileName, jpegData, photo )
								local elapsed = LrDate.currentTime() - start
										if result.status then
											local keywordCount = result.keywords and #result.keywords or 0
											local hasTitle = result.title and result.title ~= ""
											local hasCaption = result.caption and result.caption ~= ""
											local hasHeadline = result.headline and result.headline ~= ""
											local hasInstructions = result.instructions and result.instructions ~= ""
											local hasLocation = result.location and result.location ~= ""

											-- Calculate confidence based on metadata completeness
											local metadataFields = { hasTitle, hasCaption, hasHeadline, hasInstructions, hasLocation }
											local filledFields = 0
											for _, hasField in ipairs( metadataFields ) do
												if hasField then filledFields = filledFields + 1 end
											end
											local confidence = (filledFields / #metadataFields) * 0.7 + (math.min(keywordCount, 10) / 10) * 0.3
											
											trace( "completed in %.03f sec, got %d keywords, title: %s, caption: %s, headline: %s, instructions: %s, location: %s, confidence: %.2f",
												elapsed, keywordCount,
												hasTitle and "yes" or "no",
												hasCaption and "yes" or "no",
												hasHeadline and "yes" or "no",
												hasInstructions and "yes" or "no",
												hasLocation and "yes" or "no",
												confidence )
											propertyTable[ propPhotos ][ i ] = {
												photo = photo,
												keywords = result.keywords,
												title = result.title,
												caption = result.caption,
												headline = result.headline,
												instructions = result.instructions,
												location = result.location,
												elapsed = elapsed,
												confidence = confidence,
											}
											propertyTable[ propConsumedTime ] = propertyTable[ propConsumedTime ] + elapsed
											propertyTable[ propElapsedTime ] = LrDate.currentTime() - propertyTable[ propStartTime ]

											-- Force binding update by creating new array reference
											local currentPhotos = propertyTable[ propPhotos ]
											propertyTable[ propPhotos ] = currentPhotos

											-- Update progress to show completion
											if not (progressScope:isCanceled() or progressScope:isDone()) then
												progressScope:setCaption( LOC( "$$$/AiTagger/ProgressComplete=Completed: ^1 (^2 of ^3)", fileName, i, totalThumbnails ) )
												progressScope:setPortionComplete( i, totalThumbnails )
											end
										else
											-- Update progress to show error
											if not (progressScope:isCanceled() or progressScope:isDone()) then
												progressScope:setCaption( LOC( "$$$/AiTagger/ProgressError=Error analyzing ^1 (^2 of ^3)", fileName, i, totalThumbnails ) )
											end

											-- Collect error instead of showing modal dialog
											table.insert( processingErrors, { fileName = fileName, message = result.message, type = "analysis" } )
										end

										runningTasks = runningTasks - 1
										trace( "end analysis" )
							end)
						end
					)

					LrTasks.yield()
				end

				while runningTasks > 0 do
					LrTasks.sleep( 0.2 )
				end
				progressScope:done()

				logger:tracef( "done analyzing %d photos in %.02f sec (%.02f sec elapsed)", #photos, propertyTable[ propConsumedTime ], propertyTable[ propElapsedTime ] )

				-- Now that analysis is complete, show the results dialog
				if not progressScope:isCanceled() then
					-- Set final completion message
					progressScope:setCaption( LOC( "$$$/AiTagger/ProgressFinished=Analysis complete! Opening results..." ) )
					progressScope:setPortionComplete( 1, 1 )
					-- Brief pause to let user see completion message
					LrTasks.sleep( 0.5 )

					-- Show error summary if there were any processing errors
					if #processingErrors > 0 then
						local errorMessage = string.format("Processing completed with %d error(s):\n\n", #processingErrors)
						for i, error in ipairs(processingErrors) do
							errorMessage = errorMessage .. string.format("%d. %s: %s\n", i, error.fileName, error.message)
						end
						LrDialogs.message("Processing Errors", errorMessage, "warning")
					end

					-- Ensure first photo is selected before showing dialog
					if #propertyTable[ propPhotos ] > 0 and propertyTable[ propCurrentPhotoIndex ] == 0 then
						logger:tracef( "setting initial photo selection: totalPhotos=%d, photosArrayLength=%d",
							propertyTable[ propTotalPhotos ], #propertyTable[ propPhotos ] )
						propertyTable[ propCurrentPhotoIndex ] = 1
						loadPhoto( propertyTable, 1 )
					end

					showResponse( propertyTable )
				end

				inDialog = false
				progressScope:done()

				while inDialog do
					LrTasks.sleep( 1 )
				end
			end

		end
	)
end

--------------------------------------------------------------------------------
-- Begin the search
AiTagger()
