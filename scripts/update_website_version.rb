#!/usr/bin/env ruby

require_relative 'get_version'

def update_website_version
  version = get_version
  website_file = File.join(File.dirname(__FILE__), '..', 'docs', 'index.html')
  
  if !File.exist?(website_file)
    puts "ERROR: Website file not found: #{website_file}"
    exit 1
  end
  
  content = File.read(website_file)
  
  # Update download link href with GitHub raw URL for direct download
  content.gsub!(/href="https:\/\/github\.com\/obelix74\/lr-ai-image-tagger\/raw\/main\/dist\/ai-lr-tagimg-v[\d.]+\.zip"/, "href=\"https://github.com/obelix74/lr-ai-image-tagger/raw/main/dist/ai-lr-tagimg-v#{version}.zip\"")
  
  # Update download button text
  content.gsub!(/(Download\s*)v\d+\.\d+\.\d+/, "\\1v#{version}")

  
  File.write(website_file, content)
  puts "Updated website version to #{version}"
end

# If called directly, run the update
if __FILE__ == $0
  update_website_version
end