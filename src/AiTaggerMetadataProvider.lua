--[[----------------------------------------------------------------------------

 AI Image Tagger - Metadata Provider
 Copyright 2024 Anand Kumar Sankaran
 Updated for Lightroom Classic 2024 and Gemini AI

--------------------------------------------------------------------------------

AiTaggerMetadataProvider.lua
Defines custom metadata fields for AI tagging information

------------------------------------------------------------------------------]]

return {
	metadataFieldsForPhotos = {
		-- AI confidence score (0.0 to 1.0)
		{
			id = 'confidence',
			title = "AI Confidence",
			dataType = 'string',
			searchable = true,
			browsable = true,
			version = 1,
		},
		
		-- Date when AI processing occurred
		{
			id = 'processDate',
			title = "AI Process Date",
			dataType = 'string',
			searchable = true,
			browsable = true,
			version = 1,
		},
		
		-- Comma-separated list of main categories
		{
			id = 'categories',
			title = "AI Categories",
			dataType = 'string',
			searchable = true,
			browsable = true,
			version = 1,
		},
		
		-- Flag indicating if photo has been processed by AI
		{
			id = 'processed',
			title = "AI Processed",
			dataType = 'string',
			searchable = true,
			browsable = true,
			version = 1,
		},
	},
	
	schemaVersion = 1,
}