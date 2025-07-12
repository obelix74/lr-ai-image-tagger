# AI Image Tagger - Distribution Package

This directory contains the complete distribution package for AI Image Tagger, ready for deployment to a public cloud storage bucket.

## 📁 Directory Structure

```
distribution/
├── website/                    # Public-facing website
│   ├── index.html             # Main landing page
│   ├── installation.html     # Detailed installation guide
│   └── ai-image-tagger-v2.0.zip  # Plugin download
├── plugin/                    # Plugin files
│   ├── AI-Image-Tagger.lrplugin/  # Lightroom plugin directory
│   └── ai-image-tagger-v2.0.zip   # Zipped plugin for distribution
└── README.md                  # This file
```

## 🚀 Deployment Instructions

### Google Cloud Storage Deployment

1. **Create a Cloud Storage Bucket:**
   ```bash
   gsutil mb gs://your-bucket-name
   ```

2. **Configure for Website Hosting:**
   ```bash
   gsutil web set -m index.html -e 404.html gs://your-bucket-name
   ```

3. **Make Bucket Public:**
   ```bash
   gsutil iam ch allUsers:objectViewer gs://your-bucket-name
   ```

4. **Upload Website Files:**
   ```bash
   gsutil -m cp -r website/* gs://your-bucket-name/
   ```

5. **Set Proper Content Types:**
   ```bash
   gsutil -m setmeta -h "Content-Type:text/html" gs://your-bucket-name/*.html
   gsutil -m setmeta -h "Content-Type:application/zip" gs://your-bucket-name/*.zip
   ```

### Alternative Deployment Options

#### AWS S3
```bash
aws s3 sync website/ s3://your-bucket-name --acl public-read
aws s3 website s3://your-bucket-name --index-document index.html
```

#### Azure Blob Storage
```bash
az storage blob upload-batch -d '$web' -s website/ --account-name yourstorageaccount
```

#### GitHub Pages
1. Create a new repository
2. Upload the `website/` contents to the repository
3. Enable GitHub Pages in repository settings

## 🔗 Website Features

### Main Landing Page (`index.html`)
- **Responsive Design:** Works on desktop, tablet, and mobile
- **Feature Showcase:** Highlights all plugin capabilities
- **Download Integration:** Direct download links
- **API Key Instructions:** Embedded guidance for Gemini AI setup
- **Professional Styling:** Modern, clean design with animations

### Installation Guide (`installation.html`)
- **Step-by-Step Instructions:** Complete installation walkthrough
- **Troubleshooting Section:** Common issues and solutions
- **Visual Aids:** Styled for clarity and ease of use
- **API Key Setup:** Detailed Gemini AI configuration guide

## 📦 Plugin Package

### Contents
- **AI-Image-Tagger.lrplugin/:** Complete Lightroom plugin
- **All Dependencies:** JSON parser, Logger, API modules
- **Configuration Files:** Info.lua with proper metadata
- **Zipped Distribution:** Ready-to-download package

### Version Information
- **Version:** 2.0
- **Compatibility:** Adobe Lightroom Classic 2024+
- **Size:** ~50KB compressed
- **Dependencies:** Internet connection, Gemini AI API key

## 🛠 Customization

### Branding
To customize the branding:
1. Update the logo and colors in CSS files
2. Modify the `LrToolkitIdentifier` in `Info.lua` (currently: `com.anands.lightroom.aiimagetagger`)
3. Update contact information and links
4. Replace download URLs with your hosting location

### Domain Configuration
1. Update all absolute URLs in HTML files
2. Configure DNS to point to your storage bucket
3. Set up SSL certificate for HTTPS
4. Update CORS settings if needed

## 📊 Analytics & Monitoring

### Recommended Tracking
- **Google Analytics:** Add tracking code to HTML files
- **Download Tracking:** Monitor plugin download rates
- **Error Monitoring:** Track API key setup issues
- **User Feedback:** Implement feedback collection

### Performance Optimization
- **CDN:** Use CloudFlare or similar for global distribution
- **Compression:** Enable gzip compression on server
- **Caching:** Set appropriate cache headers
- **Image Optimization:** Compress any images used

## 🔒 Security Considerations

### Best Practices
- **HTTPS Only:** Ensure all traffic is encrypted
- **Content Security Policy:** Implement CSP headers
- **Regular Updates:** Keep dependencies updated
- **Access Logs:** Monitor for suspicious activity

### Privacy
- **No User Data Collection:** Plugin doesn't store personal data
- **API Key Security:** Keys stored locally in Lightroom
- **Transparent Processing:** Clear documentation of data flow

## 📈 Maintenance

### Regular Tasks
- **Monitor Download Stats:** Track plugin adoption
- **Update Documentation:** Keep installation guide current
- **Version Management:** Maintain download links
- **User Support:** Respond to issues and feedback

### Updates
When releasing new versions:
1. Update version numbers in all files
2. Create new ZIP package
3. Update download links
4. Announce changes on website
5. Maintain backward compatibility

## 🤝 Support

### User Support Channels
- **GitHub Issues:** Technical problems and bug reports
- **Email Support:** lists@anands.net
- **Documentation:** Comprehensive guides and FAQ

### Developer Resources
- **Source Code:** Available on GitHub
- **API Documentation:** Gemini AI integration details
- **Contributing Guide:** How to contribute improvements

## 📄 License & Credits

- **License:** MIT License
- **Original Author:** Tapani Otala (2017-2024)
- **Enhanced by:** Anand Kumar Sankaran (2024)
- **Powered by:** Google Gemini AI
- **Built for:** Adobe Lightroom Classic

---

**Ready for deployment to production! 🚀**
