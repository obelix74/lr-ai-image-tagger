--[[----------------------------------------------------------------------------

 AI Image Tagger
 Copyright 2017-2024 Tapani Otala, Enhanced by Anand Kumar Sankaran
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

local propPhotos = "photos"
local propCurrentPhotoIndex = "currentPhotoIndex"
local propCurrentPhotoName = "currentPhotoName"
local propTotalPhotos = "totalPhotos"
local propStartTime = "startTime"
local propElapsedTime = "elapsedTime"
local propConsumedTime = "consumedTime"
local propMaxKeywords = "maxKeywords"
local propCaption = "caption"
local propDescription = "description"
local propInstructions = "instructions"
local propCopyright = "copyright"
local propLocation = "location"

local function propKeywordTitle( i )
	return string.format( "keywordTitle%d", i )
end
local function propKeywordSelected( i )
	return string.format( "keywordSelected%d", i )
end

--------------------------------------------------------------------------------

-- save photo from propertyTable[ propXXX ] to propertyTable.photos[ i ]
local function savePhoto( propertyTable, index )
	local photo = propertyTable[ propPhotos ][ index ]
	if photo ~= nil then
		logger:tracef( "saving keyword selections" )
		local keywords = photo.keywords or { }
		for i, keyword in ipairs( keywords ) do
			keyword.selected = propertyTable[ propKeywordSelected( i ) ]
		end

		-- Save all metadata fields
		photo.caption = propertyTable[ propCaption ]
		photo.description = propertyTable[ propDescription ]
		photo.instructions = propertyTable[ propInstructions ]
		photo.copyright = propertyTable[ propCopyright ]
		photo.location = propertyTable[ propLocation ]

		logger:tracef( "saved metadata to photo data: caption='%s', description='%s', instructions='%s', copyright='%s', location='%s'",
			photo.caption or "nil", photo.description or "nil", photo.instructions or "nil",
			photo.copyright or "nil", photo.location or "nil" )
	end
end

-- load photo from propertyTable.photos[ i ] to propertyTable[ propXXX ]
local function loadPhoto( propertyTable, index )
	local photo = propertyTable[ propPhotos ][ index ]
	assert( photo ~= nil )

	local keywords = photo.keywords or { }
	logger:tracef( "updating %d keywords", #keywords )
	for i = 1, prefs.maxKeywords do
		local keyword = keywords[ i ] or { description = nil, selected = false }
		propertyTable[ propKeywordTitle( i ) ] = keyword.description
		propertyTable[ propKeywordSelected( i ) ] = keyword.selected
	end

	-- Load all metadata fields
	propertyTable[ propCaption ] = photo.caption or ""
	propertyTable[ propDescription ] = photo.description or ""
	propertyTable[ propInstructions ] = photo.instructions or ""
	propertyTable[ propCopyright ] = photo.copyright or ""
	propertyTable[ propLocation ] = photo.location or ""
end

-- select photo (i.e. move from index X to Y)
local function selectPhoto( propertyTable, newIndex )
	logger:tracef( "selecting photo %d of %d", newIndex, #propertyTable[ propPhotos ] )

	local oldIndex = propertyTable[ propCurrentPhotoIndex ]
	if oldIndex ~= newIndex then
		savePhoto( propertyTable, oldIndex )
	end

	loadPhoto( propertyTable, newIndex )
	propertyTable[ propCurrentPhotoIndex ] = newIndex
end

-- apply the selected keywords and all metadata to the photo
local function applyMetadataToPhoto( photo, keywords, caption, description, instructions, copyright, location )
	logger:tracef( "applyMetadataToPhoto called with: caption='%s', description='%s', instructions='%s', copyright='%s', location='%s'",
		caption or "nil", description or "nil", instructions or "nil", copyright or "nil", location or "nil" )

	-- Helper function to safely set metadata
	local function safeSetMetadata( fieldName, value, description )
		local success, error = pcall( function()
			photo:setRawMetadata( fieldName, value )
		end )
		if success then
			logger:tracef( "successfully set %s: %s", description, value )
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
				if decoration == decorateKeywordParent then
					parent = catalog:createKeyword( value, nil, true, nil, true )
					if parent == nil then
						logger:errorf( "failed to add parent keyword %s", value )
						return nil
					end
				end
				if decoration == decorateKeywordPrefix then
					name = string.format( "%s %s", value, name )
				elseif decoration == decorateKeywordSuffix then
					name = string.format( "%s %s", name, value )
				else
					 -- decorateKeywordAsIs or decorateKeywordParent, do nothing
				end
				logger:tracef( "creating keyword %s", name )
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
				local keywordString = table.concat( selectedKeywords, "; " )
				safeSetMetadata( "keywords", keywordString, "IPTC keywords" )
			else
				logger:tracef( "skipping IPTC keywords: enabled=%s, count=%d", tostring(prefs.saveKeywordsToIptc), #selectedKeywords )
			end

			-- Apply IPTC metadata using correct Lightroom field names
			logger:tracef( "IPTC preferences: caption=%s, description=%s, instructions=%s, copyright=%s, location=%s",
				tostring(prefs.saveCaptionToIptc), tostring(prefs.saveDescriptionToIptc),
				tostring(prefs.saveInstructionsToIptc), tostring(prefs.saveCopyrightToIptc),
				tostring(prefs.saveLocationToIptc) )



			if prefs.saveCaptionToIptc and caption and caption ~= "" then
				safeSetMetadata( "caption", caption, "IPTC caption" )
			else
				logger:tracef( "skipping IPTC caption: enabled=%s, caption='%s'", tostring(prefs.saveCaptionToIptc), caption or "nil" )
			end

			if prefs.saveDescriptionToIptc and description and description ~= "" then
				safeSetMetadata( "headline", description, "IPTC headline/description" )
			else
				logger:tracef( "skipping IPTC description: enabled=%s, description='%s'", tostring(prefs.saveDescriptionToIptc), description or "nil" )
			end

			if prefs.saveInstructionsToIptc and instructions and instructions ~= "" then
				safeSetMetadata( "instructions", instructions, "IPTC instructions" )
			end

			if prefs.saveCopyrightToIptc and copyright and copyright ~= "" then
				safeSetMetadata( "copyright", copyright, "IPTC copyright" )
			end

			if prefs.saveLocationToIptc and location and location ~= "" then
				-- Try different location fields that are known to work in Lightroom
				safeSetMetadata( "location", location, "IPTC location" )
				safeSetMetadata( "city", location, "IPTC city" )
			end
		end
	)
end

-- Export analysis results to CSV
local function exportResults( propertyTable )
	local photos = propertyTable[ propPhotos ]
	if not photos or #photos == 0 then
		LrDialogs.message( "No Results", "No analysis results to export.", "info" )
		return
	end

	local fileName = LrDialogs.runSavePanel( {
		title = "Export Analysis Results",
		label = "Save as:",
		requiredFileType = "csv",
		initialDirectory = LrPathUtils.getStandardFilePath( "desktop" ),
		initialFileName = "aiimagetagger_results_" .. LrDate.timeToUserFormat( LrDate.currentTime(), "%Y%m%d_%H%M%S" ) .. ".csv"
	} )

	if fileName then
		local file = io.open( fileName, "w" )
		if file then
			-- Write CSV header
			file:write( "Filename,Caption,Description,Keywords,Instructions,Copyright,Location,Analysis Time (sec)\n" )

			-- Write data for each photo
			for _, photoData in ipairs( photos ) do
				local photo = photoData.photo
				local filename = photo:getFormattedMetadata( "fileName" ) or ""
				local caption = (photoData.caption or ""):gsub( '"', '""' ) -- Escape quotes
				local description = (photoData.description or ""):gsub( '"', '""' )
				local instructions = (photoData.instructions or ""):gsub( '"', '""' )
				local copyright = (photoData.copyright or ""):gsub( '"', '""' )
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
					filename, caption, description, keywordStr, instructions, copyright, location, elapsed ) )
			end

			file:close()
			LrDialogs.message( "Export Complete", "Analysis results exported to:\n" .. fileName, "info" )
		else
			LrDialogs.message( "Export Failed", "Could not create file:\n" .. fileName, "error" )
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
				logger:tracef( "making the initial selection" )
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
							return value > 1
						end,
					},
					action = function( btn )
						logger:tracef( "previous photo" )
						selectPhoto( propertyTable, propertyTable[ propCurrentPhotoIndex ] - 1 )
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
							local i = values [ propCurrentPhotoIndex ]
							return values[ propPhotos ][ i + 1 ] ~= nil
						end,
					},
					action = function( btn )
						local i = propertyTable [ propCurrentPhotoIndex ]
						logger:tracef( "next photo: %d", i + 1 )
						selectPhoto( propertyTable, i + 1 )
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
				fill_horizontal = 0.6,
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogCaptionTitle=Caption" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propCaption },
						fill_horizontal = 1,
						height_in_lines = 2,
					},
				},
				f:spacer { height = 8 },
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogDescriptionTitle=Description" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propDescription },
						fill_horizontal = 1,
						height_in_lines = 4,
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
			f:spacer { width = 16 },
			f:column {
				fill_horizontal = 0.4,
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogInstructionsTitle=Instructions" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propInstructions },
						fill_horizontal = 1,
						height_in_lines = 3,
					},
				},
				f:spacer { height = 8 },
				f:group_box {
					title = LOC( "$$$/AiTagger/ResultsDialogCopyrightTitle=Copyright" ),
					font = "<system/bold>",
					f:edit_field {
						value = bind { key = propCopyright },
						fill_horizontal = 1,
						height_in_lines = 2,
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
							applyMetadataToPhoto( photo.photo, photo.keywords, photo.caption, photo.description, photo.instructions, photo.copyright, photo.location )
						end
					)
				end,
			},
			f:push_button {
				enabled = LrBinding.keyIsNot( propCurrentPhotoIndex, 0 ),
				title = LOC( "$$$/AiTagger/ResultsDialogApplyAll=Apply All" ),
				place_horizontal = 1,
				action = function()
					LrTasks.startAsyncTask(
						function()
							savePhoto( propertyTable, propertyTable[ propCurrentPhotoIndex ])
							for _, photo in ipairs( propertyTable[ propPhotos ] ) do
								applyMetadataToPhoto( photo.photo, photo.keywords, photo.caption, photo.description, photo.instructions, photo.copyright, photo.location )
							end
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
		resizable = false,
		contents = contents,
		actionVerb = LOC( "$$$/AiTagger/ResultsDialogOk=Done" ),
		cancelVerb = "< exclude >", -- magic value to hide the Cancel button
	}
end

local function AiTagger()
	LrFunctionContext.postAsyncTaskWithContext( "analyzing photos",
		function( context )
			logger:tracef( "AiTaggerMenuItem v2.0: enter" )
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
				propertyTable[ propCaption ] = ""
				propertyTable[ propDescription ] = ""
				propertyTable[ propInstructions ] = ""
				propertyTable[ propCopyright ] = ""
				propertyTable[ propLocation ] = ""

				local progressScope = LrProgressScope {
					title = LOC( "$$$/AiTagger/ProgressScopeTitle=Analyzing Photos" ),
					functionContext = context
				}
				progressScope:setCancelable( true )

				-- show the progress dialog, as an async task
				local inDialog = true
				LrTasks.startAsyncTask(
					function()
						-- Set final completion message
						if not progressScope:isCanceled() then
							progressScope:setCaption( LOC( "$$$/AiTagger/ProgressFinished=Analysis complete! Opening results..." ) )
							progressScope:setPortionComplete( 1, 1 )
							-- Brief pause to let user see completion message
							LrTasks.sleep( 0.5 )
						end

						showResponse( propertyTable )
						inDialog = false
						progressScope:done()
					end
				)

				-- Enumerate through all selected photos in the catalog
				local runningTasks = 0
				local thumbnailRequests = { }
				logger:tracef( "begin analyzing %d photos", #photos )

				-- Set initial progress message
				progressScope:setCaption( LOC( "$$$/AiTagger/ProgressStarting=Starting AI analysis of ^1 photos...", #photos ) )
				progressScope:setPortionComplete( 0, #photos )
				for i, photo in ipairs( photos ) do
					if progressScope:isCanceled() or progressScope:isDone() then
						break
					end

					-- Update the progress bar
					local fileName = photo:getFormattedMetadata( "fileName" )
					progressScope:setCaption( LOC( "$$$/AiTagger/ProgressCaption=Preparing ^1 (^2 of ^3)", fileName, i, #photos ) )
					progressScope:setPortionComplete( (i-1), #photos )

					local function trace( msg, ... )
						logger:tracef( "[%d | %d | %s] %s", #photos, i, fileName, string.format( msg, ... ) )
					end

					while ( runningTasks >= prefs.maxTasks ) and not ( progressScope:isCanceled() or progressScope:isDone() ) do
						-- logger:tracef( "%d analysis tasks running, waiting for one to finish", runningTasks )
						LrTasks.sleep( 0.2 )
					end
					runningTasks = runningTasks + 1

					trace( "begin analysis" )
					table.insert( thumbnailRequests, i, photo:requestJpegThumbnail( prefs.thumbnailWidth, prefs.thumbnailHeight,
						function( jpegData, errorMsg )
							LrTasks.startAsyncTask(
								function()
									if jpegData then
										trace( "analyzing thumbnail (%s bytes)", LrStringUtils.numberToStringWithSeparators( #jpegData, 0 ) )

										-- Update progress to show AI analysis in progress
										if not (progressScope:isCanceled() or progressScope:isDone()) then
											progressScope:setCaption( LOC( "$$$/AiTagger/ProgressAnalyzing=Analyzing with AI: ^1 (^2 of ^3)", fileName, i, #photos ) )
										end

										local start = LrDate.currentTime()
										local result = GeminiAPI.analyze( fileName, jpegData )
										local elapsed = LrDate.currentTime() - start
										if result.status then
											local keywordCount = result.keywords and #result.keywords or 0
											local hasCaption = result.caption and result.caption ~= ""
											local hasDescription = result.description and result.description ~= ""
											local hasInstructions = result.instructions and result.instructions ~= ""
											local hasCopyright = result.copyright and result.copyright ~= ""
											local hasLocation = result.location and result.location ~= ""

											trace( "completed in %.03f sec, got %d keywords, caption: %s, description: %s, instructions: %s, copyright: %s, location: %s",
												elapsed, keywordCount,
												hasCaption and "yes" or "no",
												hasDescription and "yes" or "no",
												hasInstructions and "yes" or "no",
												hasCopyright and "yes" or "no",
												hasLocation and "yes" or "no" )
											propertyTable[ propPhotos ][ i ] = {
												photo = photo,
												keywords = result.keywords,
												caption = result.caption,
												description = result.description,
												instructions = result.instructions,
												copyright = result.copyright,
												location = result.location,
												elapsed = elapsed,
											}
											propertyTable[ propConsumedTime ] = propertyTable[ propConsumedTime ] + elapsed
											propertyTable[ propElapsedTime ] = LrDate.currentTime() - propertyTable[ propStartTime ]
											propertyTable[ propPhotos ] = propertyTable[ propPhotos ] -- dummy assignment to trigger bindings

											-- Update progress to show completion
											if not (progressScope:isCanceled() or progressScope:isDone()) then
												progressScope:setCaption( LOC( "$$$/AiTagger/ProgressComplete=Completed: ^1 (^2 of ^3)", fileName, i, #photos ) )
												progressScope:setPortionComplete( i, #photos )
											end
										else
											-- Update progress to show error
											if not (progressScope:isCanceled() or progressScope:isDone()) then
												progressScope:setCaption( LOC( "$$$/AiTagger/ProgressError=Error analyzing ^1 (^2 of ^3)", fileName, i, #photos ) )
											end

											local action = LrDialogs.confirm( LOC( "$$$/AiTagger/FailedAnalysis=Failed to analyze photo ^1", fileName ), result.message )
											if action == "cancel" then
												progressScope:cancel()
											end
										end
									else
										local action = LrDialogs.confirm( LOC( "$$$/AiTagger/FailedThumbnail=Failed to generate thumbnail for ^1", fileName ), errorMsg )
										if action == "cancel" then
											progressScope:cancel()
										end
									end
									table.remove( thumbnailRequests, i )
									runningTasks = runningTasks - 1
									trace( "end analysis" )
								end
							)
						end
					) )

					LrTasks.yield()
				end

				while runningTasks > 0 do
					logger:tracef( "waiting for %d analysis tasks to finish", runningTasks )
					LrTasks.sleep( 0.2 )
				end
				thumbnailRequests = nil
				progressScope:done()

				logger:tracef( "done analyzing %d photos in %.02f sec (%.02f sec elapsed)", #photos, propertyTable[ propConsumedTime ], propertyTable[ propElapsedTime ] )

				while inDialog do
					LrTasks.sleep( 1 )
				end
			end

			logger:tracef( "AiTaggerMenuItem: exit" )
		end
	)
end

--------------------------------------------------------------------------------
-- Begin the search
AiTagger()
