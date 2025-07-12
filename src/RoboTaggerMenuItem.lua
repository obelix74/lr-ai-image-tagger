--[[----------------------------------------------------------------------------

 RoboTagger
 Copyright 2017 Tapani Otala

--------------------------------------------------------------------------------

RoboTaggerMenuItem.lua

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

		-- Save caption and description
		photo.caption = propertyTable[ propCaption ]
		photo.description = propertyTable[ propDescription ]
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

	-- Load caption and description
	propertyTable[ propCaption ] = photo.caption or ""
	propertyTable[ propDescription ] = photo.description or ""
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

-- apply the selected keywords, caption, and description to the photo
local function applyMetadataToPhoto( photo, keywords, caption, description )
	local catalog = photo.catalog
	catalog:withWriteAccessDo(
		LOC( "$$$/RoboTagger/ActionName=Apply Metadata " ),
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

			-- Apply keywords
			for _, keyword in ipairs( keywords ) do
				if keyword.selected then
					local keywordObj = createDecoratedKeyword( keyword.description, prefs.decorateKeyword, prefs.decorateKeywordValue )
					if keywordObj then
						photo:addKeyword( keywordObj )
					else
						logger:errorf( "failed to add keyword %s", keyword.description )
					end
				end
			end

			-- Apply IPTC metadata
			if prefs.saveCaptionToIptc and caption and caption ~= "" then
				photo:setRawMetadata( "caption", caption )
			end

			if prefs.saveDescriptionToIptc and description and description ~= "" then
				photo:setRawMetadata( "headline", description )
			end
		end
	)
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
					title = LOC( "$$$/RoboTagger/PrevPhoto=^U+25C0" ),
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
					title = LOC( "$$$/RoboTagger/NextPhoto=^U+25B6" ),
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
						return LOC( "$$$/RoboTagger/PhotoXofY=Photo ^1 of ^2: ^3 (^4 sec)",
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
								return LOC( "$$$/RoboTagger/PhotosRemaining=^1 photos to analyze, estimated completion in ^2 sec (^3 sec elapsed)",
									LrStringUtils.numberToStringWithSeparators( remPhotos, 0 ),
									LrStringUtils.numberToStringWithSeparators( remTime, 0 ),
									LrStringUtils.numberToStringWithSeparators( elapsedTime, 2 ) )
							else
								return LOC( "$$$/RoboTagger/PhotosRemaining=^1 photos to analyze",
									LrStringUtils.numberToStringWithSeparators( remPhotos, 0 ) )
							end
						else
							return LOC( "$$$/RoboTagger/PhotosRemaining=^1 photos analyzed in ^2 sec (^3 sec elapsed)",
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
		f:column {
			f:group_box {
				title = LOC( "$$$/RoboTagger/ResultsDialogCaptionTitle=Caption" ),
				font = "<system/bold>",
				f:edit_field {
					value = bind { key = propCaption },
					fill_horizontal = 1,
					height_in_lines = 2,
				},
			},
			f:spacer { height = 8 },
			f:group_box {
				title = LOC( "$$$/RoboTagger/ResultsDialogDescriptionTitle=Description" ),
				font = "<system/bold>",
				f:edit_field {
					value = bind { key = propDescription },
					fill_horizontal = 1,
					height_in_lines = 4,
				},
			},
			f:spacer { height = 8 },
			f:group_box {
				title = LOC( "$$$/RoboTagger/ResultsDialogKeywordsTitle=Keywords" ),
				font = "<system/bold>",
				f:row {
					place = "overlapping",
					f:column {
						f:static_text {
							visible = LrBinding.keyIsNil( propKeywordTitle( 1 ) ),
							title = LOC( "$$$/RoboTagger/NoKeywords=None" ),
							fill_horizontal = 1,
						},
					},
					f:column( keywords ),
				},
			},
		},
		f:row {
			fill_horizontal = 1,
			f:push_button {
				enabled = LrBinding.keyIsNot( propCurrentPhotoIndex, 0 ),
				title = LOC( "$$$/RoboTagger/ResultsDialogApply=Apply" ),
				place_horizontal = 1,
				action = function()
					LrTasks.startAsyncTask(
						function()
							savePhoto( propertyTable, propertyTable[ propCurrentPhotoIndex ])
							local photo = propertyTable[ propPhotos ][ propertyTable[ propCurrentPhotoIndex ] ]
							applyMetadataToPhoto( photo.photo, photo.keywords, photo.caption, photo.description )
						end
					)
				end,
			},
			f:push_button {
				enabled = LrBinding.keyIsNot( propCurrentPhotoIndex, 0 ),
				title = LOC( "$$$/RoboTagger/ResultsDialogApplyAll=Apply All" ),
				place_horizontal = 1,
				action = function()
					LrTasks.startAsyncTask(
						function()
							savePhoto( propertyTable, propertyTable[ propCurrentPhotoIndex ])
							for _, photo in ipairs( propertyTable[ propPhotos ] ) do
								applyMetadataToPhoto( photo.photo, photo.keywords, photo.caption, photo.description )
							end
						end
					)
				end,
			}
		},
	}
	local results = LrDialogs.presentModalDialog {
		title = LOC( "$$$/RoboTagger/ResultsDialogTitle=RoboTagger: Gemini AI Results" ),
		resizable = false,
		contents = contents,
		actionVerb = LOC( "$$$/RoboTagger/ResultsDialogOk=Done" ),
		cancelVerb = "< exclude >", -- magic value to hide the Cancel button
	}
end

local function RoboTagger()
	LrFunctionContext.postAsyncTaskWithContext( "analyzing photos",
		function( context )
			logger:tracef( "RoboTaggerMenuItem v2.0: enter" )
			LrDialogs.attachErrorDialogToFunctionContext( context )
			local catalog = LrApplication.activeCatalog()

			-- Check Gemini API key
			if not GeminiAPI.hasApiKey() then
				logger:errorf( "Gemini API key not configured" )
				local errorMsg = "Gemini API key not configured.\n\nPlease check:\n• Gemini API key is properly configured in plugin settings\n• API key has necessary permissions"
				LrDialogs.message( LOC( "$$$/RoboTagger/AuthFailed=Gemini API key not configured" ), errorMsg, "critical" )
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

				local progressScope = LrProgressScope {
					title = LOC( "$$$/RoboTagger/ProgressScopeTitle=Analyzing Photos" ),
					functionContext = context
				}
				progressScope:setCancelable( true )

				-- show the progress dialog, as an async task
				local inDialog = true
				LrTasks.startAsyncTask(
					function()
						showResponse( propertyTable )
						inDialog = false
						progressScope:done()
					end
				)

				-- Enumerate through all selected photos in the catalog
				local runningTasks = 0
				local thumbnailRequests = { }
				logger:tracef( "begin analyzing %d photos", #photos )
				for i, photo in ipairs( photos ) do
					if progressScope:isCanceled() or progressScope:isDone() then
						break
					end

					-- Update the progress bar
					local fileName = photo:getFormattedMetadata( "fileName" )
					progressScope:setCaption( LOC( "$$$/RoboTagger/ProgressCaption=^1 (^2 of ^3)", fileName, i, #photos ) )
					progressScope:setPortionComplete( i, #photos )

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
										local start = LrDate.currentTime()
										local result = GeminiAPI.analyze( fileName, jpegData )
										local elapsed = LrDate.currentTime() - start
										if result.status then
											trace( "completed in %.03f sec, got caption, description and %d keywords", elapsed, #result.keywords )
											propertyTable[ propPhotos ][ i ] = {
												photo = photo,
												keywords = result.keywords,
												caption = result.caption,
												description = result.description,
												elapsed = elapsed,
											}
											propertyTable[ propConsumedTime ] = propertyTable[ propConsumedTime ] + elapsed
											propertyTable[ propElapsedTime ] = LrDate.currentTime() - propertyTable[ propStartTime ]
											propertyTable[ propPhotos ] = propertyTable[ propPhotos ] -- dummy assignment to trigger bindings
										else
											local action = LrDialogs.confirm( LOC( "$$$/RoboTagger/FailedAnalysis=Failed to analyze photo ^1", fileName ), result.message )
											if action == "cancel" then
												progressScope:cancel()
											end
										end
									else
										local action = LrDialogs.confirm( LOC( "$$$/RoboTagger/FailedThumbnail=Failed to generate thumbnail for ^1", fileName ), errorMsg )
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

			logger:tracef( "RoboTaggerMenuItem: exit" )
		end
	)
end

--------------------------------------------------------------------------------
-- Begin the search
RoboTagger()
