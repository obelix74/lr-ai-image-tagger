# Gemini Gemini AI Image Tagger for Adobe Lightroom Classic

**Automatically tag your photos with AI-powered captions, descriptions, and keywords using Google's Gemini AI.**

![Gemini Gemini AI Image Tagger](https://img.shields.io/badge/Lightroom-Classic%202024-blue) ![Gemini AI](https://img.shields.io/badge/Powered%20by-Gemini%20AI-orange) ![Version](https://img.shields.io/badge/version-2.4.0-green)

## 🚀 Features

### **AI-Powered Analysis**
- **Smart Captions**: Generate concise, descriptive captions (1-2 sentences)
- **Detailed Descriptions**: Create comprehensive descriptions (2-3 sentences)
- **Intelligent Keywords**: Extract relevant keywords automatically
- **Usage Instructions**: Get AI suggestions for photo editing and usage
- **Copyright Detection**: Identify visible copyright or attribution information
- **Location Recognition**: Detect identifiable landmarks and locations

### **Professional Metadata Management**
- **Complete IPTC Support**: Save all metadata to industry-standard IPTC fields
- **Smart Keyword Storage**: Keywords saved to Lightroom Keywords (automatically included in IPTC on export)
- **Configurable Options**: Choose which metadata fields to save
- **Batch Processing**: Analyze multiple photos efficiently with rate limiting
- **Export Functionality**: Export analysis results to CSV for external processing

### **Advanced Customization**
- **Custom Prompts**: Create your own AI analysis prompts
- **Batch Configuration**: Adjust batch size and processing delays
- **Keyword Management**: Select/deselect keywords with bulk actions
- **Professional UI**: Two-column layout optimized for workflow efficiency

## 📋 Requirements

- **Adobe Lightroom Classic 2024** (or newer)
- **Google Gemini AI API Key** (free tier available)
- **Internet Connection** for AI analysis

## 🔧 Installation

### Step 1: Download the Plugin
1. Download the latest release from the [plugin website](https://obelix74.github.io/lr-gemini-ai-image-tagger/)
2. Extract the ZIP file to a folder on your computer

### Step 2: Install in Lightroom
1. Open Adobe Lightroom Classic
2. Go to **File > Plug-in Manager**
3. Click **Add** button
4. Navigate to the extracted plugin folder and select it
5. Click **Done**

### Step 3: Get Gemini AI API Key
1. Visit [Google AI Studio](https://ai.google.dev/gemini-api/docs/api-key)
2. Sign in with your Google account
3. Click **Get API Key**
4. Create a new API key or use an existing one
5. Copy the API key (keep it secure!)

### Step 4: Configure the Plugin
1. In Lightroom, go to **File > Plug-in Manager**
2. Select **Gemini AI Image Tagger** from the list
3. Paste your Gemini AI API key in the **API Key** field
4. Configure your preferred settings:
   - Choose which IPTC metadata fields to save
   - Set batch processing options
   - Customize AI prompts (optional)
5. Click **Done**

## 🎯 Usage

### Basic Usage
1. Select one or more photos in Lightroom's Library module
2. Go to **Library > Plug-in Extras > Tag Photos with AI**
3. Wait for AI analysis to complete
4. Review and edit the generated metadata:
   - **Caption**: Brief description
   - **Description**: Detailed description
   - **Keywords**: Select relevant keywords
   - **Instructions**: Usage suggestions
   - **Copyright**: Attribution info
   - **Location**: Identified landmarks
5. Click **Apply** for current photo or **Apply All** for all photos

### Advanced Features

#### Custom Prompts
- Enable **Use custom prompt** in plugin settings
- Write your own AI analysis instructions
- Tailor the AI output to your specific needs

#### Batch Processing
- Configure **Batch Size** (1-10 photos per batch)
- Set **Delay Between Requests** to avoid rate limiting
- Monitor progress in the analysis dialog

#### Export Results
- Click **Export Results** to save analysis data as CSV
- Files saved as `aiimagetagger_results_YYYYMMDD_HHMMSS.csv`
- Includes all metadata fields and processing times
- Perfect for workflow documentation and analysis

## ⚙️ Configuration Options

### IPTC Metadata Settings
- ✅ **Save caption to IPTC metadata**
- ✅ **Save description to IPTC metadata**
- ⬜ **Save keywords to IPTC metadata** (Note: Keywords automatically included in IPTC on export)
- ⬜ **Save instructions to IPTC metadata**
- ⬜ **Save copyright to IPTC metadata**
- ⬜ **Save location to IPTC metadata**

### AI Prompt Customization
- **Use custom prompt**: Enable/disable custom AI instructions
- **Custom Prompt**: Write your own analysis instructions

### Batch Processing
- **Batch Size**: 1-10 photos (default: 5)
- **Delay Between Requests**: 500-5000ms (default: 1000ms)

### Keyword Management
- **Create Keywords**: Choose decoration style (as-is, prefix, suffix, parent)
- **Keyword Value**: Custom text for decoration

## 🔒 Privacy & Security

- **API Key Security**: Keys are stored securely in Lightroom's password storage
- **Data Processing**: Images are sent to Google's Gemini AI service for analysis
- **No Storage**: Your images are not stored by the AI service
- **Local Processing**: All metadata management happens locally in Lightroom

## 🆘 Troubleshooting

### Common Issues

**"API key not configured"**
- Ensure you've entered a valid Gemini AI API key in plugin settings
- Check that the API key has proper permissions

**"Network error"**
- Verify your internet connection
- Check if your firewall allows Lightroom to access the internet
- Try increasing the delay between requests

**"Analysis failed"**
- Some images may not be suitable for AI analysis
- Try with different image formats (JPEG works best)
- Check the Lightroom log for detailed error messages

### Getting Help
- Contact support: [lists@anands.net](mailto:lists@anands.net)

## 📊 API Usage & Costs

### Gemini AI Free Tier
- **15 requests per minute**
- **1,500 requests per day**
- **1 million tokens per month**

### Cost Optimization Tips
- Use batch processing with appropriate delays
- Process images during off-peak hours
- Consider upgrading to paid tier for heavy usage

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Credits

- **Created By**: Anand's Photography (2025)
- **Powered by**: Google Gemini AI
- **Built for**: Adobe Lightroom Classic

## 🙏 Acknowledgements

Special thanks to [@tjotala](https://github.com/tjotala) for [lr-robotagger](https://github.com/tjotala/lr-robotagger), which provided the inspiration to get started with this project.

## 🔗 Links

- [Plugin Homepage](https://obelix74.github.io/lr-gemini-ai-image-tagger/)

- [Google Gemini AI](https://ai.google.dev)
- [Adobe Lightroom Classic](https://www.adobe.com/products/photoshop-lightroom-classic.html)

---

**Made with ❤️ for photographers and content creators worldwide**
