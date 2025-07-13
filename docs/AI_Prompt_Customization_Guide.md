# AI Prompt Customization Guide
## AI Image Tagger for Adobe Lightroom Classic

### Table of Contents
1. [Overview](#overview)
2. [Accessing Prompt Customization](#accessing-prompt-customization)
3. [Using Preset Prompts](#using-preset-prompts)
4. [Loading Custom Prompts from Files](#loading-custom-prompts-from-files)
5. [Creating Custom Prompts](#creating-custom-prompts)
6. [Available Preset Prompts](#available-preset-prompts)
7. [Prompt Structure Guidelines](#prompt-structure-guidelines)
8. [Troubleshooting](#troubleshooting)

---

## Overview

AI Image Tagger provides powerful prompt customization features that allow you to tailor the AI analysis to your specific photography needs. You can choose from 13 professionally crafted preset prompts, load custom prompts from text files, or create your own prompts directly in the interface.

### Key Features
- **13 Preset Prompts** covering all major photography genres
- **File System Integration** for loading custom prompts from .txt files
- **Inline Editing** with a large, scrollable text area
- **Smart Defaults** that work out of the box
- **Professional Results** optimized for IPTC metadata standards

---

## Accessing Prompt Customization

1. **Open Plugin Manager**: In Lightroom Classic, go to `File > Plug-in Manager`
2. **Select AI Image Tagger**: Click on "AI Image Tagger" in the left panel
3. **Navigate to AI Section**: Scroll down to the "AI Prompt Customization" section
4. **Enable Custom Prompts**: Check the "Use custom prompt" checkbox

![AI Prompt Customization Interface](../media/prompt_customization.png)

---

## Using Preset Prompts

### Quick Start
1. **Enable Custom Prompts**: Check "Use custom prompt"
2. **Select Preset**: Click the dropdown menu next to "Preset Prompts"
3. **Choose Your Style**: Select from 13 specialized prompts
4. **Apply**: The prompt will automatically load into the text area

### Preset Selection Tips
- **Sports Photography**: Perfect for games, athletes, and jersey identification
- **Nature & Wildlife**: Optimized for species identification and behavior
- **Architecture**: Focuses on building styles, materials, and design
- **Food Photography**: Emphasizes cuisine, ingredients, and presentation
- **Fashion Photography**: Captures style, mood, and aesthetic elements

---

## Loading Custom Prompts from Files

### File Requirements
- **Format**: Plain text files (.txt or .text)
- **Encoding**: UTF-8 recommended
- **Size**: No specific limit, but keep prompts focused and concise

### Loading Process
1. **Prepare Your File**: Create a .txt file with your custom prompt
2. **Click Browse**: Use the "Browse File..." button
3. **Select File**: Navigate to your prompt file and select it
4. **Automatic Loading**: The content will load into the prompt field
5. **Review & Edit**: Make any final adjustments in the text area

### Example File Structure
```
Custom Sports Analysis Prompt

Please analyze this sports photograph with focus on:
1. Player identification and jersey numbers
2. Game situation and action
3. Team colors and uniforms
4. Venue and crowd context

Format as JSON:
{
  "title": "descriptive title",
  "caption": "action description",
  "headline": "detailed analysis",
  "keywords": "sport, team, action, player number",
  "instructions": "editing notes",
  "copyright": "attribution if visible",
  "location": "venue if identifiable"
}
```

---

## Creating Custom Prompts

### Best Practices
1. **Be Specific**: Clearly define what you want the AI to identify
2. **Use Structure**: Organize your requirements in numbered lists
3. **Specify Format**: Always request JSON output for consistency
4. **Include Examples**: Show the AI the exact format you want
5. **Test Iteratively**: Refine your prompts based on results

### Essential Elements
- **Analysis Instructions**: What to look for in the image
- **Output Format**: JSON structure with required fields
- **Field Definitions**: Clear explanation of each metadata field
- **Context Guidelines**: Specific focus areas for your photography type

### JSON Structure Template
```json
{
  "title": "short descriptive title (2-5 words)",
  "caption": "brief description (1-2 sentences)",
  "headline": "detailed description (2-3 sentences)",
  "keywords": "comma-separated keywords",
  "instructions": "editing or usage notes",
  "copyright": "copyright info if visible",
  "location": "location if identifiable"
}
```

---

## Available Preset Prompts

### 1. **Sports Photography**
- **Focus**: Player identification, jersey numbers, game action
- **Special Features**: Recognizes specific player numbers and names
- **Best For**: Team sports, athletic events, player portraits

### 2. **Nature & Wildlife**
- **Focus**: Species identification, behavior, environmental context
- **Special Features**: Conservation status, seasonal characteristics
- **Best For**: Wildlife photography, nature documentation

### 3. **Architecture**
- **Focus**: Building styles, materials, design elements
- **Special Features**: Historical periods, structural features
- **Best For**: Building photography, urban architecture

### 4. **Portrait & People**
- **Focus**: Mood, lighting, composition
- **Special Features**: Respects privacy (no individual identification)
- **Best For**: Portrait sessions, people photography

### 5. **Events & Weddings**
- **Focus**: Special moments, emotions, celebrations
- **Special Features**: Cultural and religious elements
- **Best For**: Wedding photography, special events

### 6. **Travel & Landscape**
- **Focus**: Geographical features, cultural landmarks
- **Special Features**: Tourism and travel context
- **Best For**: Travel photography, landscape documentation

### 7. **Product Photography**
- **Focus**: Commercial features, branding, market appeal
- **Special Features**: Technical specifications, target audience
- **Best For**: E-commerce, product catalogs

### 8. **Street Photography**
- **Focus**: Urban scenes, human activity, documentary style
- **Special Features**: Cultural and social context
- **Best For**: Street photography, urban documentation

### 9. **Automotive Photography**
- **Focus**: Vehicle identification, automotive features
- **Special Features**: Make/model recognition, car culture
- **Best For**: Car shows, automotive events, vehicle portraits

### 10. **Food Photography**
- **Focus**: Cuisine identification, presentation style
- **Special Features**: Ingredients, cultural significance
- **Best For**: Restaurant photography, food blogging

### 11. **Fashion Photography**
- **Focus**: Fashion elements, style analysis, aesthetic mood
- **Special Features**: Trend identification, styling choices
- **Best For**: Fashion shoots, style documentation

### 12. **Macro Photography**
- **Focus**: Close-up subjects, technical details
- **Special Features**: Magnification techniques, scientific value
- **Best For**: Macro photography, detailed studies

### 13. **Abstract Photography**
- **Focus**: Visual elements, artistic concepts
- **Special Features**: Creative interpretation, color theory
- **Best For**: Abstract art, creative photography

---

## Prompt Structure Guidelines

### Effective Prompt Components

1. **Clear Instructions**
   ```
   Please analyze this [photography type] photograph and provide:
   ```

2. **Specific Requirements**
   ```
   1. A short title (2-5 words)
   2. A brief caption (1-2 sentences)
   3. A detailed headline/description (2-3 sentences)
   4. A list of relevant keywords
   5. Special instructions for editing
   6. Copyright information (if visible)
   7. Location information (if identifiable)
   ```

3. **Focus Areas**
   ```
   Focus on:
   - [Specific element 1]
   - [Specific element 2]
   - [Technical aspects]
   - [Context considerations]
   ```

4. **JSON Format Specification**
   ```
   Please format your response as JSON with the following structure:
   {
     "title": "example title",
     "caption": "example caption",
     ...
   }
   ```

### Common Mistakes to Avoid
- ❌ Vague instructions ("analyze this photo")
- ❌ Missing JSON format specification
- ❌ Inconsistent field names
- ❌ Overly complex requirements
- ❌ No specific focus areas

### Optimization Tips
- ✅ Use specific photography terminology
- ✅ Include context about your workflow
- ✅ Specify keyword preferences
- ✅ Request consistent formatting
- ✅ Test with sample images

---

## Troubleshooting

### Common Issues

**Problem**: Prompt doesn't load from file
- **Solution**: Check file format (.txt or .text), ensure UTF-8 encoding
- **Check**: File permissions and location accessibility

**Problem**: AI results don't match expectations
- **Solution**: Refine prompt specificity, add more detailed instructions
- **Check**: JSON format specification is correct

**Problem**: Keywords not relevant
- **Solution**: Add specific keyword guidelines to your prompt
- **Check**: Include examples of desired keyword types

**Problem**: Inconsistent output format
- **Solution**: Ensure JSON structure is clearly specified
- **Check**: All required fields are defined in the prompt

### Getting Help
- **Email Support**: lists@anands.net
- **Documentation**: Check the latest version of this guide
- **Community**: Share prompts and tips with other users

---

*Created by Anand's Photography • Powered by Google Gemini AI*
