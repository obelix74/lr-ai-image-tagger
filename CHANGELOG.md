# Changelog
## AI Image Tagger for Adobe Lightroom Classic

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [6.1.0] - 2025-01-16

### Added
- **🔄 Automatic Model Migration**: Users with Gemini 1.5 Flash are automatically upgraded to Gemini 2.5 Flash for better performance
- **📋 Version Tracking**: Plugin now tracks version history for future automated migrations
- **⚡ Performance Upgrade**: Default Gemini model upgraded from 1.5 Flash to 2.5 Flash (same cost, better results)

### Enhanced
- **🔧 Migration System**: Robust version migration framework for seamless future updates
- **📊 Improved Defaults**: New installations get Gemini 2.5 Flash as the optimal default model
- **🔍 Migration Logging**: Clear logging of automatic model upgrades for transparency

### Technical
- **Version Migration Logic**: Automatic detection and upgrade of outdated model preferences
- **Backward Compatibility**: Existing preferences preserved while upgrading critical settings
- **Future-Proof**: Foundation for automated configuration updates in future releases

### Migration Notes
- **Existing 1.5 Flash users**: Automatically upgraded to 2.5 Flash on plugin load
- **Other models**: No changes to existing Gemini 2.0 Flash, 2.5 Pro, or other provider settings
- **No action required**: Migration happens transparently on next Lightroom restart

---

## [5.0.0] - 2025-08-16

### Added
- **🚀 OpenAI GPT-4V Integration**: Full support for OpenAI's GPT-4 with Vision models including GPT-4o and GPT-4-turbo
- **🔀 Three AI Providers**: Choose between Google Gemini, OpenAI GPT-4V, or local Ollama processing
- **🎯 GPT-4o Support**: Latest OpenAI model with enhanced vision capabilities and improved accuracy
- **🔧 Unified Provider Interface**: Seamless switching between all three AI providers through factory pattern
- **🔐 Enhanced Security**: Secure API key storage with encryption for all providers
- **⚡ Advanced Error Handling**: Robust retry logic, exponential backoff, and rate limiting for OpenAI API

### Enhanced
- **🎛️ Provider Selection**: Updated UI with three-way provider selection (Gemini/OpenAI/Ollama)
- **📊 Provider Status**: Real-time connection testing and status indicators for all providers
- **🔄 Smart Fallbacks**: Intelligent error recovery and retry mechanisms
- **📈 Performance**: Optimized request handling and response parsing across all providers
- **🌐 Industry Standards**: OpenAI Chat Completions API integration following best practices

### Technical
- **New Files**: Complete OpenAI API implementation with vision model support
- **Enhanced Architecture**: Provider factory pattern supporting three distinct AI services
- **API Compliance**: Full OpenAI Chat Completions API integration with image analysis
- **Response Processing**: Advanced JSON parsing with markdown code block extraction
- **Rate Limiting**: Intelligent request throttling respecting provider-specific limits
- **Backward Compatibility**: Seamless migration from previous versions

### Provider Comparison
- **Google Gemini**: Free tier available, excellent quality, Google's latest AI
- **OpenAI GPT-4V**: Industry-leading vision model, pay-per-use (~$0.01-0.03/image), premium quality  
- **Ollama**: Complete privacy, no internet required, free after download, local processing

### Breaking Changes
- **None**: Existing Gemini and Ollama configurations continue working without changes
- **Version Jump**: Major version increment (4.x → 5.x) reflects significant new capabilities

### Migration Notes
- Existing users: Plugin will continue using your current provider (Gemini/Ollama)
- New OpenAI option: Available in provider dropdown after installation
- No configuration changes required for current users
- OpenAI requires API key with billing enabled (pay-per-use model)

---

## [4.0.0] - 2025-07-29

### Added
- **🆕 Ollama Support**: Full integration with local Ollama AI models for privacy-focused processing
- **🔄 AI Provider Selection**: Choose between Google Gemini (cloud) or Ollama (local) processing
- **🏭 Provider Factory Pattern**: Clean architecture supporting multiple AI providers
- **⚙️ Ollama Configuration**: Settings for server URL, model selection, and timeout configuration
- **🔒 Local Processing**: Complete privacy with Ollama - images never leave your computer
- **📚 Multi-Provider Documentation**: Updated docs with setup instructions for both providers

### Changed
- **🏷️ Plugin Rebranding**: Updated name from "Gemini AI Image Tagger" to "AI Image Tagger"
- **🎛️ Enhanced UI**: Provider selection dropdown with conditional configuration sections
- **📄 Updated Documentation**: Comprehensive comparison between Gemini and Ollama providers
- **🔧 Improved Settings**: Reorganized plugin settings for better provider management

### Technical
- **New Files**: `OllamaAPI.lua`, `AIProviderFactory.lua` for provider abstraction
- **Updated Files**: `AiTaggerMenuItem.lua`, `AiTaggerInfoProvider.lua` for multi-provider support
- **Architecture**: Provider factory pattern with unified API interface
- **Backwards Compatibility**: Existing Gemini setups continue working seamlessly

### Migration Notes
- Existing users: Plugin will continue using Gemini by default
- No configuration changes required for current Gemini users
- New users can choose their preferred AI provider during setup

---

## [3.5.0] - 2025-07-16

### Changed
- **Auto Collections Simplification**: Removed smart collections option from configuration UI
- **Enhanced Collection Management**: Streamlined auto collections to focus on working functionality only
- **Improved User Experience**: Eliminated disabled/non-functional smart collections option

### Fixed  
- **Configuration Clarity**: Removed references to smart collections that were disabled due to Lightroom SDK limitations
- **UI Consistency**: Auto collections configuration now only shows functional options
- **Help Text Accuracy**: Updated collection help text to reflect actual capabilities

### Technical
- **Code Cleanup**: Removed all smart collections related code and UI elements
- **Preference Management**: Simplified collection preferences to working features only
- **Localization Updates**: Removed smart collections strings from all translation files

---

## [3.4.0] - 2025-07-16

### Added
- **Complete Internationalization**: Full localization support for all 16 languages supported by Adobe Lightroom Classic
- **Multi-Language UI**: Comprehensive translation of all user-facing strings and interface elements
- **Global Accessibility**: Native language support for English, Spanish, French, German, Italian, Portuguese, Russian, Japanese, Korean, Chinese (Simplified & Traditional), Dutch, Polish, Swedish, Norwegian, and Thai
- **TranslatedStrings System**: Implemented Adobe Lightroom SDK localization standard with proper string namespacing

### Enhanced
- **Language Coverage**: All 94 user interface strings translated professionally across 16 languages
- **Technical Terminology**: Accurate photography and AI-specific terminology in each language
- **Cultural Adaptation**: Localized text that respects cultural and linguistic conventions
- **Unicode Support**: Full support for non-Latin scripts including Japanese, Chinese, Korean, Thai, Russian, and Arabic

### Technical
- **Lightroom SDK Compliance**: Proper `$$$/AiTagger/` namespace implementation for all localized strings
- **File Structure**: Individual TranslatedStrings files for each supported language (e.g., `TranslatedStrings_es.txt`)
- **Placeholder Handling**: Consistent support for dynamic content placeholders (^1, ^2, etc.) across all languages
- **Deployment Infrastructure**: Fixed deployment script directory structure and path resolution issues

### Fixed
- **Deployment Scripts**: Corrected file path issues in `deploy_private.sh` and `deploy.sh`
- **Directory Structure**: Updated deployment validation to match actual project structure
- **Build Process**: Improved deployment reliability and error handling

### International Markets
- **European Union**: German, French, Italian, Spanish, Portuguese, Dutch, Polish, Swedish support
- **Asia Pacific**: Japanese, Korean, Chinese (Simplified & Traditional), Thai support  
- **Americas**: English, Spanish, Portuguese support
- **Nordic Region**: Swedish, Norwegian support
- **Global Reach**: Russian and additional language support for worldwide accessibility

---

## [3.3.0] - 2025-07-15

### Added
- **Internationalization**: Support for multiple languages results from Gemini
- **Internationalization**: All plugin text customizable in differnt languages
---


## [3.0.0] - 2025-07-15

### Added
- **Complete Plugin Rebrand**: Transitioned from "AI Image Tagger" to "Gemini AI Image Tagger"
- **Enhanced Metadata Support**: Added support for sending GPS location and EXIF metadata to AI analysis
- **Privacy Controls**: New option to include/exclude GPS and EXIF data for enhanced privacy
- **Improved Website Integration**: Updated all URLs and branding to new tagimg.net domain

### Enhanced
- **Plugin Identity**: Updated plugin identifier to `net.tagimg.ai-lr-tagimg`
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
