# OpenAI Integration Testing Guide

## 🧪 Testing Status: Ready for Live Testing

The OpenAI integration has passed all offline validation tests and is ready for testing in Adobe Lightroom Classic.

## 📦 Installation

### Plugin Location
- **Development Build**: `build/ai-lr-tagimg.lrplugin/`
- **Distribution Package**: `dist/ai-lr-tagimg-v5.0.0.zip`

### Installation Steps
1. Open Adobe Lightroom Classic
2. Go to **File > Plug-in Manager**
3. Click **Add** button
4. Navigate to `build/ai-lr-tagimg.lrplugin/` folder and select it
5. Click **Done** to complete installation

## 🔑 OpenAI API Setup

### Prerequisites
- Valid OpenAI account with API access
- GPT-4 with Vision model access (required for image analysis)
- API key with sufficient credits/usage quota

### API Key Configuration
1. In Lightroom, go to **File > Plug-in Manager**
2. Select **AI Image Tagger** plugin
3. Click **Configure** or settings button
4. Enter your OpenAI API key (starts with `sk-`)
5. Select **OpenAI GPT-4V** as provider
6. Choose model (recommended: `gpt-4o`)

## 🧪 Test Plan

### Phase 1: Basic Functionality Tests

#### Test 1.1: Plugin Loading
- [ ] Plugin loads without errors in Lightroom
- [ ] No error messages in Lightroom's log
- [ ] Plugin appears in File menu

#### Test 1.2: Provider Selection
- [ ] OpenAI appears in provider list
- [ ] Can select "OpenAI GPT-4V" as provider
- [ ] Provider description shows correctly

#### Test 1.3: API Key Management
- [ ] Can enter OpenAI API key in settings
- [ ] API key is stored securely (not visible in plain text)
- [ ] Can clear/change API key

#### Test 1.4: Connection Testing
- [ ] Connection test passes with valid API key
- [ ] Connection test fails gracefully with invalid key
- [ ] Appropriate error messages displayed

### Phase 2: Image Analysis Tests

#### Test 2.1: Single Image Analysis
1. Select a single photo in Lightroom Library
2. Go to **Library > Analyze Selected Photos**
3. Verify:
   - [ ] Analysis starts without errors
   - [ ] Progress dialog appears
   - [ ] Analysis completes successfully
   - [ ] Results dialog shows with metadata fields populated

#### Test 2.2: Metadata Quality
Check that generated metadata is reasonable:
- [ ] **Title**: Short, descriptive (2-5 words)
- [ ] **Caption**: Brief description (1-2 sentences)
- [ ] **Headline**: Detailed description (2-3 sentences)
- [ ] **Keywords**: Relevant keywords (comma-separated)
- [ ] **Instructions**: Editing suggestions (if applicable)
- [ ] **Location**: Geographic location (if identifiable)

#### Test 2.3: Hierarchical Keywords
If hierarchical keywords are enabled:
- [ ] Keywords use " > " separator format
- [ ] Keywords follow hierarchy (broad > specific)
- [ ] Keywords create proper hierarchy in Lightroom

#### Test 2.4: Batch Processing
1. Select 3-5 photos in Lightroom
2. Run analysis on batch
3. Verify:
   - [ ] All photos processed without errors
   - [ ] Progress updates correctly
   - [ ] Rate limiting respected (no 429 errors)
   - [ ] Each photo gets appropriate metadata

### Phase 3: Advanced Feature Tests

#### Test 3.1: Custom Prompts
- [ ] Can set custom analysis prompt
- [ ] Custom prompt affects analysis results
- [ ] Can revert to default prompt

#### Test 3.2: Language Support
- [ ] Can set response language (if other than English)
- [ ] Results appear in selected language
- [ ] Keywords respect language setting

#### Test 3.3: EXIF/GPS Metadata Integration
- [ ] Can enable EXIF/GPS data sharing
- [ ] Camera metadata included in analysis
- [ ] GPS coordinates enhance location detection
- [ ] Privacy option to disable metadata sharing

#### Test 3.4: Provider Switching
- [ ] Can switch between Gemini, Ollama, and OpenAI
- [ ] Each provider works independently
- [ ] Settings preserved when switching
- [ ] No conflicts between providers

### Phase 4: Error Handling Tests

#### Test 4.1: API Errors
Test with various error conditions:
- [ ] Invalid API key → Clear error message
- [ ] Expired API key → Authentication error
- [ ] Rate limit exceeded → Graceful retry with backoff
- [ ] Network timeout → Retry mechanism
- [ ] Insufficient credits → Clear billing error

#### Test 4.2: Image Issues
- [ ] Very large images → Proper resizing/encoding
- [ ] Corrupted image data → Error handling
- [ ] Unsupported format → Graceful failure
- [ ] Empty image selection → Appropriate message

#### Test 4.3: Response Issues
- [ ] Malformed JSON response → Fallback parsing
- [ ] Empty/minimal response → Default handling
- [ ] Network interruption → Retry logic
- [ ] Service unavailable → Error reporting

### Phase 5: Performance Tests

#### Test 5.1: Response Times
- [ ] Single image analysis: < 10 seconds typical
- [ ] Batch processing: Reasonable progress
- [ ] No memory leaks during batch processing
- [ ] UI remains responsive during analysis

#### Test 5.2: Quality Comparison
Compare OpenAI results with Gemini/Ollama:
- [ ] OpenAI provides good quality analysis
- [ ] Keywords are relevant and useful
- [ ] Descriptions are accurate and detailed
- [ ] Location detection works well

## 🐛 Troubleshooting

### Common Issues and Solutions

#### "API key not configured"
- Ensure valid OpenAI API key is entered
- Check that key has GPT-4V model access
- Verify key has remaining credits

#### "Rate limit exceeded"
- Wait for rate limit reset (usually 1 minute)
- Reduce batch size in settings
- Check OpenAI dashboard for usage limits

#### "Model not found" or "Access denied"
- Ensure your OpenAI plan includes GPT-4V access
- Try different model (gpt-4-vision-preview)
- Contact OpenAI support for model access

#### Analysis fails or returns empty results
- Check internet connection
- Verify image is supported format
- Try with smaller/different image
- Check Lightroom's log for detailed errors

#### Plugin doesn't load
- Verify plugin folder structure is correct
- Check Lightroom version compatibility
- Look for Lua syntax errors in console

### Debug Information

#### Lightroom Logs
- **Windows**: `%APPDATA%\Adobe\Lightroom\Logs\`
- **macOS**: `~/Library/Logs/Adobe/Lightroom/`

#### Plugin Logging
Look for entries containing:
- `OpenAI:` - OpenAI API operations
- `AIProviderFactory:` - Provider selection and routing
- Error details with request/response information

## 📊 Success Criteria

### Minimum Viable Test
- [ ] Plugin loads successfully
- [ ] Can select OpenAI as provider
- [ ] Can analyze single image with valid results
- [ ] Generated metadata is reasonable quality

### Full Integration Test
- [ ] All basic functionality tests pass
- [ ] Batch processing works reliably
- [ ] Error handling is graceful
- [ ] Performance is acceptable
- [ ] Quality matches or exceeds other providers

## 🚀 Next Steps After Testing

### If Tests Pass
1. **Production Deployment**: Package for distribution
2. **Documentation**: Update user guides with OpenAI instructions
3. **Version Release**: Tag new version with OpenAI support
4. **User Communication**: Announce OpenAI availability

### If Issues Found
1. **Document Issues**: Note specific problems and error messages
2. **Debug Information**: Collect logs and error details
3. **Priority Assessment**: Determine critical vs. minor issues
4. **Fix Planning**: Plan fixes based on severity

## 💡 Testing Tips

### Best Practices
- Start with small test images (< 5MB)
- Use diverse image types (landscape, portrait, objects, people)
- Test both RAW and JPEG formats
- Keep OpenAI usage dashboard open to monitor costs
- Test during different times to check API availability

### Image Selection for Testing
- **Landscape**: Mountains, beaches, cityscapes
- **Portrait**: People in various settings
- **Objects**: Food, products, artwork
- **Complex scenes**: Multiple subjects, busy backgrounds
- **Edge cases**: Very dark/bright, abstract, minimal content

### Expected Costs
- Typical cost per image: $0.01-0.03 USD
- Monitor usage to avoid unexpected charges
- Set up billing alerts in OpenAI dashboard

---

## 📋 Test Results Template

```
## OpenAI Integration Test Results - [Date]

### Environment
- Lightroom Version: ________
- Plugin Version: v5.0.0
- OS: ________
- OpenAI Model: ________

### Test Results
- [x] Plugin Loading: ✅ / ❌
- [x] Provider Selection: ✅ / ❌  
- [x] API Key Management: ✅ / ❌
- [x] Single Image Analysis: ✅ / ❌
- [x] Batch Processing: ✅ / ❌
- [x] Error Handling: ✅ / ❌

### Issues Found
1. [Describe any issues]
2. [Include error messages]
3. [Note reproducibility]

### Quality Assessment
- Metadata Quality: Excellent / Good / Fair / Poor
- Compared to Gemini: Better / Similar / Worse
- Overall Satisfaction: ___/10

### Notes
[Additional observations and feedback]
```

Ready to begin testing! 🚀