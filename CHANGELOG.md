# Changelog
## AI Image Tagger for Adobe Lightroom Classic

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.2.0] - 2025-07-15

### Added
- **Automatic Language Detection**: Gemini AI now automatically responds in the user's Lightroom language
- **Multi-Language AI Support**: AI-generated metadata (titles, captions, keywords) returned in detected language
- **Enhanced Multi-Language Experience**: Complete integration between localized UI and AI responses

### Enhanced
- **Intelligent Language Switching**: Plugin detects Lightroom language and instructs Gemini accordingly
- **Seamless Localization**: No user configuration required - works automatically with Lightroom's language setting
- **All Prompt Types**: Language detection applies to default prompts, custom prompts, and preset prompts
- **Consistent Experience**: Both UI and AI responses now match the user's preferred language

### Fixed
- **Localized UI Display**: Fixed localization display issues - now shows clean localized text
- **Language Detection**: Resolved `getCurrentLocale()` error with proper Lightroom SDK implementation
- **Translation Accuracy**: Improved localization accuracy for various UI elements

### Technical
- **Language Detection System**: Implemented robust language detection using LOC() function testing
- **Prompt Enhancement**: All prompts automatically include language instructions when non-English
- **Fallback Mechanisms**: Multiple detection methods ensure reliable language identification
- **SDK Compatibility**: Removed non-existent LrLocalization functions for better stability

---


## [3.0.0] - 2025-07-15

### Added
- **Complete Plugin Rebrand**: Transitioned from "AI Image Tagger" to "Gemini AI Image Tagger"
- **Enhanced Metadata Support**: Added support for sending GPS location and EXIF metadata to AI analysis
- **Privacy Controls**: New option to include/exclude GPS and EXIF data for enhanced privacy
- **Improved Website Integration**: Updated all URLs and branding to new tagimg.net domain

### Enhanced
- **Plugin Identity**: Updated plugin identifier to `net.tagimg.gemini-lr-tagimg`
- **Metadata Analysis**: Optional GPS coordinates and technical metadata sharing with Gemini AI
- **User Control**: Configurable privacy settings for metadata sharing
- **Professional Branding**: Complete visual and textual rebrand throughout the plugin

### Technical
- **Domain Migration**: Updated all references from aitagger.anands.net to lr.tagimg.net
- **Plugin Identifier**: Changed from legacy identifier to new standardized format
- **Privacy Options**: Added `includeGpsExifData` preference for user control
- **Build System**: Updated version numbering to 3.0.0 for major release

### Breaking Changes
- **Plugin Identifier**: Changed plugin identifier requires reinstallation
- **URL Updates**: All help and documentation URLs updated to new domain
- **Version Jump**: Major version increment reflects significant structural changes

---

## [2.3.3] - 2025-07-14

### Added
- **Enhanced Metadata Options**: Added option to send GPS location and EXIF metadata with AI analysis
- **Privacy Controls**: New setting to include/exclude technical metadata for enhanced privacy

### Enhanced
- **Analysis Accuracy**: Optional GPS coordinates and camera settings can improve AI analysis quality
- **User Control**: Configurable metadata sharing preferences in plugin settings
- **Documentation**: Updated help text to explain metadata sharing options

### Technical
- **Metadata Integration**: Enhanced API calls to include optional GPS and EXIF data
- **Privacy Settings**: Added `includeGpsExifData` preference with default privacy-focused setting

---

## [2.3.2] - 2025-07-13

### Fixed
- **Build Process**: Updated version numbers and build system for proper distribution
- **Documentation**: Updated all version references to maintain consistency

### Technical
- **Version Management**: Incremented patch version from 2.3.1 to 2.3.2
- **Build System**: Updated Rakefile package naming for new version

---

## [2.3.1] - 2025-01-13

### Enhanced
- **Improved Button Layout**: Moved Done button to same row as Apply and Apply All buttons for better workflow
- **Better User Experience**: Buttons now arranged as Apply | Apply All | Done | Export Results for logical grouping

### Technical
- **UI Layout Update**: Updated results dialog button arrangement for more intuitive interaction
- **Dialog Optimization**: Removed redundant dialog action buttons in favor of inline button layout

---

## [2.3.0] - 2025-01-13

### Enhanced
- **Wider Results Window**: Increased overall dialog width to 900px minimum for better data visibility
- **Larger Text Fields**: Expanded field widths (Title/Caption/Headline: 500px, Instructions/Copyright/Location: 350px)
- **Improved Layout**: Optimized column proportions (65%/35%) with reduced spacing between columns
- **Resizable Dialog**: Made results window resizable for users who need even more space
- **Better User Experience**: Significantly improved viewing and editing experience for AI-generated metadata

### Technical
- **UI Improvements**: Enhanced dialog layout for modern screen resolutions
- **Field Optimization**: Better utilization of available screen real estate

---

## [2.2.1] - 2025-01-13

### Fixed
- **Text Field Usability**: Removed unreliable `resizable = true` property that wasn't working in Lightroom SDK
- **Improved Text Areas**: Increased default heights for better content visibility
- **Enhanced Layout**: Better proportions between left and right columns (65%/35%)

### Enhanced
- **Caption Field**: Increased from 2 to 3 lines with text wrapping
- **Headline Field**: Increased from 4 to 5 lines with text wrapping
- **Instructions Field**: Increased from 3 to 4 lines with text wrapping
- **Copyright Field**: Increased from 2 to 3 lines with text wrapping
- **Location Field**: Increased from 2 to 3 lines with text wrapping
- **Custom Prompt Field**: Increased from 6 to 8 lines with text wrapping

### Technical
- **Text Wrapping**: Added `wrap = true` to all multi-line text fields
- **Reliable Scrolling**: Maintained `scrollable = true` for all text fields
- **SDK Compatibility**: Removed problematic properties for better cross-version compatibility

---

## [2.2.0] - 2025-01-13

### Added
- **5 New Preset Prompts**: Automotive Photography, Food Photography, Fashion Photography, Macro Photography, Abstract Photography
- **Enhanced Text Field UI**: All metadata text fields now support scrolling and resizing
- **Example Prompt Files**: Concert Photography, Real Estate Photography, Pet Photography examples
- **Comprehensive Documentation**: Complete user guides, quick reference, and installation instructions

### Enhanced
- **Scrollable Text Fields**: Title field now scrollable for long titles
- **Resizable Text Areas**: Copyright and Location fields now resizable and scrollable
- **User Experience**: Improved usability with drag-to-resize functionality across all metadata fields
- **Documentation**: Expanded documentation with 13 preset descriptions and usage examples

### Technical
- **Total Presets**: Expanded from 8 to 13 professional preset prompts
- **UI Consistency**: Standardized scrollable/resizable behavior across all text input fields
- **File Structure**: Organized documentation with examples and quick reference guides

---

## [2.1.0] - 2024-12-XX

### Added
- **AI Prompt Customization**: Complete custom prompt system
- **8 Preset Prompts**: Sports, Nature & Wildlife, Architecture, Portrait & People, Events & Weddings, Travel & Landscape, Product, Street Photography
- **File System Integration**: Load custom prompts from .txt files
- **Inline Prompt Editing**: Large, scrollable text area for prompt creation
- **Smart UI Controls**: Enable/disable custom prompt functionality

### Enhanced
- **Caption Field**: Made scrollable and resizable
- **Headline Field**: Made scrollable and resizable  
- **Instructions Field**: Made scrollable and resizable
- **Progress Indicators**: Improved user feedback during analysis

### Technical
- **PromptPresets.lua**: New module for managing preset prompts
- **GeminiAPI.lua**: Enhanced with prompt loading and preset management functions
- **AiTaggerInfoProvider.lua**: Complete UI for prompt customization

---

## [2.0.0] - 2024-11-XX

### Added
- **Google Gemini AI Integration**: Replaced Google Vision API with Gemini AI
- **Enhanced Metadata Support**: Title, Caption, Headline, Instructions, Copyright, Location
- **IPTC Metadata Compliance**: Industry-standard metadata field mapping
- **Batch Processing**: Efficient multi-photo analysis with configurable batch sizes
- **Export Functionality**: CSV export of analysis results

### Enhanced
- **API Management**: Secure API key storage and management
- **Error Handling**: Robust error recovery and user feedback
- **Performance**: Optimized for large photo collections
- **User Interface**: Modern, intuitive interface design

### Technical
- **Gemini AI API**: Complete integration with Google's latest AI model
- **JSON Processing**: Structured output parsing and validation
- **Progress Tracking**: Real-time analysis progress and status updates

---

## [1.x] - 2024-XX-XX

### Added
- **Initial Release**: Basic AI-powered photo tagging
- **Google Vision API**: Original AI integration
- **Keyword Generation**: Automatic keyword extraction
- **Lightroom Integration**: Plugin architecture and menu integration

---

## Version Numbering

- **Major Version** (X.0.0): Breaking changes, major feature overhauls
- **Minor Version** (0.X.0): New features, enhancements, additional presets
- **Patch Version** (0.0.X): Bug fixes, minor improvements, documentation updates

---

## Support

For questions, bug reports, or feature requests:
- **Email**: lists@anands.net
- **Documentation**: Check the docs/ folder for detailed guides
- **Website**: Visit our website for the latest downloads and information

---

*Created by Anand's Photography • Powered by Google Gemini AI*
