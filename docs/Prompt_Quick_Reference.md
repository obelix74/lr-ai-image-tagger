# AI Prompt Customization - Quick Reference
## AI Image Tagger for Adobe Lightroom Classic

### 🚀 Quick Start
1. **Enable**: Check "Use custom prompt" in plugin settings
2. **Choose**: Select from 13 preset prompts OR load from file OR edit manually
3. **Apply**: Start analyzing photos with your custom prompt

---

### 📋 Available Presets

| Preset | Best For | Key Features |
|--------|----------|--------------|
| **Sports Photography** | Team sports, athletes | Jersey numbers, player identification |
| **Nature & Wildlife** | Animals, nature | Species ID, behavior, conservation |
| **Architecture** | Buildings, structures | Styles, materials, design elements |
| **Portrait & People** | People photography | Mood, lighting, composition |
| **Events & Weddings** | Special occasions | Emotions, moments, celebrations |
| **Travel & Landscape** | Travel, scenery | Geography, landmarks, culture |
| **Product Photography** | Commercial products | Features, branding, market appeal |
| **Street Photography** | Urban scenes | Human activity, documentary style |
| **Automotive Photography** | Cars, vehicles | Make/model, features, car culture |
| **Food Photography** | Cuisine, dining | Ingredients, presentation, culture |
| **Fashion Photography** | Style, clothing | Fashion elements, trends, aesthetics |
| **Macro Photography** | Close-ups, details | Magnification, textures, technical |
| **Abstract Photography** | Artistic, creative | Visual elements, concepts, interpretation |

---

### 📁 File Loading
- **Supported**: .txt and .text files
- **Encoding**: UTF-8 recommended
- **Location**: Any accessible folder on your computer
- **Process**: Browse File... → Select → Auto-load

---

### ✏️ Custom Prompt Template

```
[Photography Type] Analysis Prompt

Please analyze this [type] photograph and provide:
1. A short title (2-5 words)
2. A brief caption (1-2 sentences)
3. A detailed headline/description (2-3 sentences)
4. A list of relevant keywords
5. Special instructions for editing
6. Copyright information (if visible)
7. Location information (if identifiable)

Focus on:
- [Specific element 1]
- [Specific element 2]
- [Technical aspects]
- [Context considerations]

Please format your response as JSON:
{
  "title": "descriptive title",
  "caption": "brief description",
  "headline": "detailed description",
  "keywords": "keyword1, keyword2, keyword3",
  "instructions": "editing notes",
  "copyright": "copyright info if visible",
  "location": "location if identifiable"
}
```

---

### 🎯 Prompt Optimization Tips

**DO:**
- ✅ Be specific about what to identify
- ✅ Use photography terminology
- ✅ Specify JSON format clearly
- ✅ Include focus areas
- ✅ Test with sample images

**DON'T:**
- ❌ Use vague instructions
- ❌ Forget JSON format specification
- ❌ Make overly complex requirements
- ❌ Skip field definitions

---

### 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| File won't load | Check .txt format, UTF-8 encoding |
| Inconsistent results | Add more specific instructions |
| Wrong keywords | Include keyword examples in prompt |
| Format errors | Verify JSON structure specification |

---

### 📞 Support
- **Email**: lists@anands.net
- **Documentation**: Full guide available in docs folder
- **Tips**: Test prompts with different image types

---

*AI Image Tagger • Created by Anand's Photography*
