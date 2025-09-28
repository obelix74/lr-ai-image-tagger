# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an AI Image Tagger plugin for Adobe Lightroom Classic that automatically generates captions, descriptions, and keywords using Google's Gemini AI API or local Ollama models. The plugin integrates with Lightroom's SDK to analyze selected photos and populate IPTC metadata fields.

## Core Architecture

### Plugin Structure
- **src/**: Source Lua files for the Lightroom plugin
- **build/**: Local development build directory with plugin files
- **dist/**: Distribution packages (.zip files)
- **docs/**: GitHub Pages website files

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
- Plugin identifier: `net.tagimg.ai-lr-tagimg`

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
- Install with: Download Lightroom classic SDK, and copy luac from the distribution to PATH: https://developer.adobe.com/lightroom-classic/
- For development, can work with source .lua files directly

## API Integration

### Google Gemini AI
- Uses Gemini 2.5 Flash model (default)
- API endpoint: `https://generativelanguage.googleapis.com/v1beta`
- Rate limiting: 15 requests/minute, 1,500 requests/day (free tier)
- Supports custom prompts and preset templates

### Metadata Fields
- **Caption**: Brief 1-2 sentence description
- **Description**: Detailed 2-3 sentence description  
- **Keywords**: Extracted relevant keywords
- **Instructions**: Usage and editing suggestions
- **Location**: Identified landmarks and locations

## File Locations

### Plugin Installation
For local development, built plugin resides in `build/ai-lr-tagimg.lrplugin/` and can be installed directly in Lightroom via File > Plug-in Manager.
For deployment, plugin is packaged in `dist/ai-lr-tagimg-v#{version}.zip` and distributed via GitHub releases.

### Documentation
- `README.md`: User-facing documentation and installation guide
- `docs/`: Additional user guides and prompt examples
- `CHANGELOG.md`: Version history and feature changes

### Deployment
- Edit VERSION file
- rake update_version
- rake clean
- rake clobber
- rake package
- Upload package to GitHub release and update docs/index.html

### Download Links
- Always use raw GitHub links for direct file downloads, not release page links
- Format: `https://github.com/obelix74/lr-ai-image-tagger/raw/refs/heads/main/dist/ai-lr-tagimg-v#{version}.zip`
- This ensures immediate availability without requiring GitHub release publication

## Release Process

### Updating Version for Release
When releasing a new version, the `rake update_version` task will automatically update:
1. **docs/index.html**: Updates download link and button text to match VERSION file
2. **src/Info.lua**: Updates plugin version metadata

The website now uses GitHub Pages with docs/ directory and downloads link directly to GitHub releases.

## Important Notes

- Plugin stores API keys securely using Lightroom's password storage
- Images are temporarily uploaded to Google's Gemini AI service for analysis
- All metadata processing happens locally within Lightroom
- Supports batch processing with configurable delays to respect API limits
- Compatible with Lightroom Classic 2024 and newer versions