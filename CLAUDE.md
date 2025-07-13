# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an AI Image Tagger plugin for Adobe Lightroom Classic that automatically generates captions, descriptions, and keywords using Google's Gemini AI API. The plugin integrates with Lightroom's SDK to analyze selected photos and populate IPTC metadata fields.

## Core Architecture

### Plugin Structure
- **src/**: Source Lua files for the Lightroom plugin
- **distribution/plugin/AI-Image-Tagger.lrplugin/**: Built plugin files ready for installation
- **build/**: Temporary build directory (created during compilation)
- **dist/**: Distribution packages (.zip files)

### Key Components
- **Info.lua**: Plugin manifest defining SDK version, menu items, and metadata
- **AiTaggerMenuItem.lua**: Main UI dialog and photo processing logic
- **GeminiAPI.lua**: Google Gemini AI API integration and HTTP communication
- **Logger.lua**: Logging utilities for debugging
- **PromptPresets.lua**: AI prompt templates and customization
- **JSON.lua**: JSON parsing library
- **inspect.lua**: Lua table inspection utility

### Lightroom SDK Integration
- Uses Lightroom SDK version 13.0 (minimum 10.0)
- Adds menu items to Library and Export menus
- Processes selected photos in batches
- Writes metadata to IPTC fields and Lightroom keywords
- Plugin identifier: `net.tagimg.aiimagetagger`

## Development Commands

### Build System (Rake-based)
```bash
# Show version information
rake version

# Build plugin without compilation (development)
rake build_source

# Package plugin without compilation
rake package_source

# Test Lua compiler and compile source files
rake compile

# Create production package (compiled)
rake package

# Clean temporary files
rake clean

# Remove all generated files
rake clobber
```

### Development Workflow
1. **Source Development**: Work directly in `src/` directory
2. **Testing**: Use `rake build_source` to create uncompiled plugin for testing
3. **Production**: Use `rake package` to create compiled distribution

### Lua Requirements
- Lua 5.1 compiler required for production builds
- Install with: `brew install lua@5.1 && brew link lua@5.1 --force`
- For development, can work with source .lua files directly

## API Integration

### Google Gemini AI
- Uses Gemini 1.5 Flash model
- API endpoint: `https://generativelanguage.googleapis.com/v1beta`
- Rate limiting: 15 requests/minute, 1,500 requests/day (free tier)
- Supports custom prompts and preset templates

### Metadata Fields
- **Caption**: Brief 1-2 sentence description
- **Description**: Detailed 2-3 sentence description  
- **Keywords**: Extracted relevant keywords
- **Instructions**: Usage and editing suggestions
- **Copyright**: Detected attribution information
- **Location**: Identified landmarks and locations

## File Locations

### Plugin Installation
Built plugin resides in `distribution/plugin/AI-Image-Tagger.lrplugin/` and can be installed directly in Lightroom via File > Plug-in Manager.

### Documentation
- `README.md`: User-facing documentation and installation guide
- `docs/`: Additional user guides and prompt examples
- `CHANGELOG.md`: Version history and feature changes

### Distribution
- `dist/ai-image-tagger-v2.3.0.zip`: Current production package
- Website assets in `distribution/website/`

## Important Notes

- Plugin stores API keys securely using Lightroom's password storage
- Images are temporarily uploaded to Google's Gemini AI service for analysis
- All metadata processing happens locally within Lightroom
- Supports batch processing with configurable delays to respect API limits
- Compatible with Lightroom Classic 2024 and newer versions