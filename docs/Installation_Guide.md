# Installation Guide
## AI Image Tagger for Adobe Lightroom Classic

### System Requirements

**Adobe Lightroom Classic**
- Version 2024 or newer
- Windows 10/11 or macOS 10.15+
- 8GB RAM recommended
- Internet connection required

**Google Gemini AI API**
- Free Google account
- API key (free tier available)
- 15 requests/minute, 1,500/day limit (free)

---

## Step 1: Download the Plugin

1. **Visit the Download Page**: Go to our website download section
2. **Download Latest Version**: Click "Download v2.1.0 (Latest)"
3. **Save the File**: Save `ai-image-tagger-v2.1.0.zip` to your Downloads folder
4. **Extract Files**: Unzip the downloaded file to reveal the plugin folder

---

## Step 2: Install in Lightroom Classic

### Method 1: Plug-in Manager (Recommended)
1. **Open Lightroom Classic**
2. **Access Plug-in Manager**: Go to `File > Plug-in Manager`
3. **Add Plugin**: Click the "Add" button in the bottom left
4. **Navigate to Plugin**: Browse to the extracted plugin folder
5. **Select Plugin**: Choose the main plugin folder (contains Info.lua)
6. **Confirm Installation**: Click "Add Plug-in"

### Method 2: Direct Installation
1. **Locate Lightroom Plugins Folder**:
   - **Windows**: `%APPDATA%\Adobe\Lightroom\Modules`
   - **macOS**: `~/Library/Application Support/Adobe/Lightroom/Modules`
2. **Copy Plugin Folder**: Copy the extracted plugin folder here
3. **Restart Lightroom**: Close and reopen Lightroom Classic
4. **Verify Installation**: Check `File > Plug-in Manager` for the plugin

---

## Step 3: Get Your Google Gemini AI API Key

### Create API Key
1. **Visit Google AI Studio**: Go to [https://ai.google.dev/gemini-api/docs/api-key](https://ai.google.dev/gemini-api/docs/api-key)
2. **Sign In**: Use your Google account to sign in
3. **Create API Key**: Click "Get API Key" button
4. **Generate New Key**: Click "Create API key in new project"
5. **Copy Key**: Copy the generated API key (keep it secure!)

### Free Tier Limits
- **Requests**: 15 per minute
- **Daily Limit**: 1,500 requests per day
- **Monthly Tokens**: 1 million tokens
- **Cost**: Completely free

---

## Step 4: Configure the Plugin

### Initial Setup
1. **Open Plugin Settings**: Go to `File > Plug-in Manager`
2. **Select AI Image Tagger**: Click on the plugin in the left panel
3. **Enter API Key**: Paste your Gemini AI API key in the "API Key" field
4. **Test Connection**: The plugin will verify your API key automatically

### Configure Options (Optional)
1. **General Options**:
   - **Max Parallel Requests**: Adjust based on your internet speed (default: 3)
   
2. **Keyword Options**:
   - **Create Keywords**: Choose how to format AI-generated keywords
   - **IPTC Metadata**: Enable saving to IPTC fields
   
3. **AI Prompt Customization**:
   - **Use Custom Prompt**: Enable to access preset prompts
   - **Preset Prompts**: Choose from 13 professional presets
   - **Browse File**: Load custom prompts from text files

---

## Step 5: First Analysis

### Quick Test
1. **Select Photos**: Choose 1-3 photos in Lightroom Library
2. **Start Analysis**: Go to `Library > Plug-in Extras > Tag Photos with AI`
3. **Monitor Progress**: Watch the progress bar and status messages
4. **Review Results**: Check the generated metadata in the results dialog
5. **Apply Metadata**: Click "Apply" to save metadata to your photos

### Verify Installation
- ✅ **Plugin Appears**: In Plug-in Manager and Library menu
- ✅ **API Key Works**: No authentication errors
- ✅ **Analysis Completes**: Photos are successfully analyzed
- ✅ **Metadata Applied**: Keywords and descriptions are added

---

## Troubleshooting

### Common Installation Issues

**Plugin Not Appearing**
- **Solution**: Restart Lightroom Classic completely
- **Check**: Verify plugin folder contains Info.lua file
- **Path**: Ensure plugin is in correct Lightroom modules folder

**API Key Errors**
- **Solution**: Verify API key is copied correctly (no extra spaces)
- **Check**: Ensure API key is enabled in Google AI Studio
- **Test**: Try generating a new API key

**Network Connection Issues**
- **Solution**: Check internet connection and firewall settings
- **Check**: Verify Lightroom can access external websites
- **Proxy**: Configure proxy settings if required

**Permission Errors**
- **Solution**: Run Lightroom as administrator (Windows) or check folder permissions (macOS)
- **Check**: Ensure user has write access to Lightroom folders

### Getting Help

**Before Contacting Support**
1. Check this troubleshooting section
2. Verify system requirements are met
3. Try restarting Lightroom Classic
4. Test with a single photo first

**Contact Information**
- **Email**: lists@anands.net
- **Subject**: Include "AI Image Tagger Installation" in subject line
- **Details**: Include Lightroom version, operating system, and error messages

---

## Next Steps

### Learn the Features
1. **Read Documentation**: Check the full user guide
2. **Explore Presets**: Try different prompt presets for your photography style
3. **Customize Prompts**: Create custom prompts for specialized workflows
4. **Optimize Settings**: Adjust batch sizes and processing options

### Best Practices
1. **Start Small**: Begin with a few photos to understand the workflow
2. **Choose Appropriate Presets**: Match prompts to your photography type
3. **Review Results**: Always review AI-generated metadata before applying
4. **Backup Catalogs**: Maintain regular Lightroom catalog backups

---

## Uninstallation

### Remove Plugin
1. **Open Plug-in Manager**: Go to `File > Plug-in Manager`
2. **Select Plugin**: Click on AI Image Tagger
3. **Remove**: Click "Remove" button
4. **Confirm**: Confirm removal when prompted
5. **Restart**: Restart Lightroom Classic

### Clean Up
- **API Key**: Optionally disable or delete API key in Google AI Studio
- **Plugin Files**: Remove plugin folder from Lightroom modules directory
- **Settings**: Plugin preferences are automatically removed

---

*Installation complete! You're ready to start using AI Image Tagger.*

**Created by Anand's Photography • Powered by Google Gemini AI**
