#!/bin/bash

# AI Image Tagger - Deployment Script
# Deploys the website and plugin to Google Cloud Storage

set -e  # Exit on any error

# Configuration - Use environment variables or provide as arguments
BUCKET_NAME="${BUCKET_NAME:-lr.tagimg.net}"
PROJECT_ID="${PROJECT_ID:-}"
REGION="${REGION:-us-central1}"

# Validate required configuration
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}[ERROR]${NC} PROJECT_ID environment variable is required."
    echo "Usage: PROJECT_ID=your-project-id BUCKET_NAME=your-bucket ./deploy.sh"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v gsutil &> /dev/null; then
        print_error "gsutil is not installed. Please install Google Cloud SDK."
        exit 1
    fi
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud is not installed. Please install Google Cloud SDK."
        exit 1
    fi
    
    print_success "All dependencies are installed."
}

# Function to get configuration from user
get_configuration() {
    print_status "Using pre-configured bucket: $BUCKET_NAME"

    if [ -z "$PROJECT_ID" ]; then
        if [ "$QUICK_MODE" = true ]; then
            print_error "Project ID is required. Use: $0 --project YOUR_PROJECT_ID --quick"
            exit 1
        else
            echo -n "Enter your Google Cloud Project ID: "
            read PROJECT_ID
        fi
    fi

    if [ -z "$PROJECT_ID" ]; then
        print_error "Project ID is required for deployment."
        exit 1
    fi

    print_status "Configuration:"
    echo "  Bucket: $BUCKET_NAME"
    echo "  Project: $PROJECT_ID"
    echo "  Region: $REGION"
    echo
}

# Function to authenticate with Google Cloud
authenticate() {
    print_status "Checking Google Cloud authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_warning "Not authenticated with Google Cloud. Starting authentication..."
        gcloud auth login
    fi
    
    # Set the project
    gcloud config set project "$PROJECT_ID"
    print_success "Authenticated and project set."
}

# Function to create and configure the bucket
setup_bucket() {
    print_status "Setting up Google Cloud Storage bucket: $BUCKET_NAME"

    # Check if bucket exists
    if gsutil ls -b "gs://$BUCKET_NAME" &> /dev/null; then
        print_warning "Bucket $BUCKET_NAME already exists. Checking ownership..."

        # Check if we have access to the bucket
        if gsutil ls "gs://$BUCKET_NAME" &> /dev/null; then
            print_success "Bucket access confirmed. Proceeding with deployment."
        else
            print_error "Cannot access bucket $BUCKET_NAME. Please check permissions or use a different bucket name."
            exit 1
        fi
    else
        print_status "Creating bucket $BUCKET_NAME..."
        if gsutil mb -p "$PROJECT_ID" -c STANDARD -l "$REGION" "gs://$BUCKET_NAME"; then
            print_success "Bucket created successfully."
        else
            print_error "Failed to create bucket. Please check your project ID and permissions."
            exit 1
        fi
    fi
    
    # Configure for website hosting
    print_status "Configuring bucket for website hosting..."
    gsutil web set -m index.html -e 404.html "gs://$BUCKET_NAME"
    
    # Make bucket public
    print_status "Making bucket publicly accessible..."
    gsutil iam ch allUsers:objectViewer "gs://$BUCKET_NAME"
    
    print_success "Bucket configured for website hosting."
}

# Function to deploy website files
deploy_website() {
    print_status "Deploying website files..."
    
    # Upload all files from website directory
    gsutil -m cp -r website/* "gs://$BUCKET_NAME/"
    
    # Set proper content types
    print_status "Setting content types..."
    gsutil -m setmeta -h "Content-Type:text/html" "gs://$BUCKET_NAME/*.html"
    gsutil -m setmeta -h "Content-Type:application/zip" "gs://$BUCKET_NAME/*.zip"
    gsutil -m setmeta -h "Content-Type:text/css" "gs://$BUCKET_NAME/*.css" 2>/dev/null || true
    gsutil -m setmeta -h "Content-Type:application/javascript" "gs://$BUCKET_NAME/*.js" 2>/dev/null || true
    
    # Set cache control for static assets
    gsutil -m setmeta -h "Cache-Control:public, max-age=3600" "gs://$BUCKET_NAME/*.css" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:public, max-age=3600" "gs://$BUCKET_NAME/*.js" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:public, max-age=86400" "gs://$BUCKET_NAME/*.zip"
    
    print_success "Website files deployed successfully."
}

# Function to configure custom domain
configure_custom_domain() {
    print_status "Configuring custom domain: lr.tagimg.net"

    # Add the custom domain to the bucket
    print_status "Adding custom domain to bucket..."
    gsutil web set -m index.html -e 404.html gs://$BUCKET_NAME

    print_status "Custom domain configuration complete!"
    echo
    print_warning "Manual DNS setup required:"
    echo "  1. In your DNS provider (tagimg.net), create a CNAME record:"
    echo "     Name: aitagger"
    echo "     Value: c.storage.googleapis.com"
    echo "  2. Verify domain ownership in Google Search Console"
    echo "  3. Wait for DNS propagation (up to 24 hours)"
    echo
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check if main files exist
    if gsutil ls "gs://$BUCKET_NAME/index.html" &> /dev/null; then
        print_success "index.html deployed successfully."
    else
        print_error "index.html not found in bucket."
        exit 1
    fi
    
    if gsutil ls "gs://$BUCKET_NAME/installation.html" &> /dev/null; then
        print_success "installation.html deployed successfully."
    else
        print_error "installation.html not found in bucket."
        exit 1
    fi
    
    if gsutil ls "gs://$BUCKET_NAME/gemini-lr-tagimg-v3.1.0.zip" &> /dev/null; then
        print_success "Plugin ZIP file deployed successfully."
    else
        print_error "Plugin ZIP file not found in bucket."
        exit 1
    fi
    
    # Get the website URLs
    WEBSITE_URL="https://storage.googleapis.com/$BUCKET_NAME/index.html"
    CUSTOM_DOMAIN_URL="https://lr.tagimg.net"

    print_success "Deployment verification complete!"
    echo
    print_status "Your website is now live at:"
    echo "  Primary URL: $WEBSITE_URL"
    echo "  Custom Domain: $CUSTOM_DOMAIN_URL (if configured)"
    echo
    print_status "To set up the custom domain (lr.tagimg.net):"
    echo "  1. Create a CNAME record: lr.tagimg.net → c.storage.googleapis.com"
    echo "  2. Verify domain ownership in Google Search Console"
    echo "  3. Add the domain to your bucket with: gsutil web set -m index.html -e 404.html gs://$BUCKET_NAME"
    echo "  4. Test the custom domain: curl -I $CUSTOM_DOMAIN_URL"
    echo
}

# Function to test the deployment
test_deployment() {
    print_status "Testing deployment..."

    local website_url="https://storage.googleapis.com/$BUCKET_NAME/index.html"

    # Test if the website is accessible
    if command -v curl &> /dev/null; then
        print_status "Testing website accessibility..."
        if curl -s -o /dev/null -w "%{http_code}" "$website_url" | grep -q "200"; then
            print_success "Website is accessible at: $website_url"
        else
            print_warning "Website may not be immediately accessible. DNS propagation can take time."
        fi

        # Test download link
        local download_url="https://storage.googleapis.com/$BUCKET_NAME/gemini-lr-tagimg-v3.1.0.zip"
        if curl -s -o /dev/null -w "%{http_code}" "$download_url" | grep -q "200"; then
            print_success "Plugin download is accessible at: $download_url"
        else
            print_warning "Plugin download may not be immediately accessible."
        fi
    else
        print_warning "curl not found. Cannot test website accessibility automatically."
        print_status "Please manually test: $website_url"
    fi

    echo
}

# Function to show usage information
show_usage() {
    echo "AI Image Tagger - Deployment Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -b, --bucket BUCKET_NAME    Google Cloud Storage bucket name (default: lr-ai-tagger)"
    echo "  -p, --project PROJECT_ID    Google Cloud Project ID (required)"
    echo "  -r, --region REGION         Google Cloud region (default: us-central1)"
    echo "  -h, --help                  Show this help message"
    echo "  --quick                     Quick setup with minimal prompts"
    echo
    echo "Examples:"
    echo "  $0 --project my-gcp-project"
    echo "  $0 --project my-gcp-project --quick"
    echo "  $0 --project my-gcp-project --bucket custom-bucket-name"
    echo
    echo "Quick Setup:"
    echo "  The script is pre-configured for the lr-ai-tagger bucket."
    echo "  Just provide your Google Cloud Project ID to get started!"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bucket)
            BUCKET_NAME="$2"
            print_status "Using custom bucket: $BUCKET_NAME"
            shift 2
            ;;
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        --quick)
            QUICK_MODE=true
            print_status "Quick mode enabled - minimal prompts"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main deployment process
main() {
    echo "🚀 AI Image Tagger Deployment Script"
    echo "======================================"
    echo
    
    check_dependencies
    get_configuration
    authenticate
    setup_bucket
    deploy_website
    verify_deployment
    test_deployment
    
    echo
    print_success "🎉 Deployment completed successfully!"
    echo
    # Ask if user wants to configure custom domain (skip in quick mode)
    if [ "$QUICK_MODE" != true ]; then
        echo
        echo -n "Would you like to configure the custom domain (lr.tagimg.net)? [y/N]: "
        read configure_domain
        if [[ $configure_domain =~ ^[Yy]$ ]]; then
            configure_custom_domain
        fi
    else
        print_status "Quick mode: Skipping custom domain configuration"
    fi

    print_status "Next steps:"
    echo "  1. Test your website at the URLs above"
    echo "  2. Configure Google Analytics (optional)"
    echo "  3. Monitor download statistics"
    echo "  4. Update DNS if you chose custom domain setup"
    echo
}

# Check if script is being run from the correct directory
if [ ! -d "website" ] || [ ! -d "plugin" ]; then
    print_error "This script must be run from the distribution directory."
    print_error "Make sure you're in the directory containing 'website' and 'plugin' folders."
    exit 1
fi

# Run main function
main
