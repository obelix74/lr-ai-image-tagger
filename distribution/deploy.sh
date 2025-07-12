#!/bin/bash

# AI Image Tagger - Deployment Script
# Deploys the website and plugin to Google Cloud Storage

set -e  # Exit on any error

# Configuration
BUCKET_NAME=""
PROJECT_ID=""
REGION="us-central1"

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
    if [ -z "$BUCKET_NAME" ]; then
        echo -n "Enter your Google Cloud Storage bucket name: "
        read BUCKET_NAME
    fi
    
    if [ -z "$PROJECT_ID" ]; then
        echo -n "Enter your Google Cloud Project ID: "
        read PROJECT_ID
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
    print_status "Setting up Google Cloud Storage bucket..."
    
    # Check if bucket exists
    if gsutil ls -b "gs://$BUCKET_NAME" &> /dev/null; then
        print_warning "Bucket $BUCKET_NAME already exists."
    else
        print_status "Creating bucket $BUCKET_NAME..."
        gsutil mb -p "$PROJECT_ID" -c STANDARD -l "$REGION" "gs://$BUCKET_NAME"
        print_success "Bucket created successfully."
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
    
    if gsutil ls "gs://$BUCKET_NAME/ai-image-tagger-v2.0.zip" &> /dev/null; then
        print_success "Plugin ZIP file deployed successfully."
    else
        print_error "Plugin ZIP file not found in bucket."
        exit 1
    fi
    
    # Get the website URL
    WEBSITE_URL="https://storage.googleapis.com/$BUCKET_NAME/index.html"
    
    print_success "Deployment verification complete!"
    echo
    print_status "Your website is now live at:"
    echo "  $WEBSITE_URL"
    echo
    print_status "You can also set up a custom domain by:"
    echo "  1. Creating a CNAME record pointing to c.storage.googleapis.com"
    echo "  2. Verifying domain ownership in Google Search Console"
    echo "  3. Adding the domain to your bucket"
    echo
}

# Function to show usage information
show_usage() {
    echo "AI Image Tagger - Deployment Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -b, --bucket BUCKET_NAME    Google Cloud Storage bucket name"
    echo "  -p, --project PROJECT_ID    Google Cloud Project ID"
    echo "  -r, --region REGION         Google Cloud region (default: us-central1)"
    echo "  -h, --help                  Show this help message"
    echo
    echo "Example:"
    echo "  $0 --bucket my-aitagger-site --project my-gcp-project"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bucket)
            BUCKET_NAME="$2"
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
    
    echo
    print_success "🎉 Deployment completed successfully!"
    echo
    print_status "Next steps:"
    echo "  1. Test your website at the URL above"
    echo "  2. Set up a custom domain (optional)"
    echo "  3. Configure Google Analytics (optional)"
    echo "  4. Monitor download statistics"
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
