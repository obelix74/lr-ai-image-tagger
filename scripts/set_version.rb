#!/usr/bin/env ruby

require_relative 'get_version'

def set_version(new_version)
  # Validate version format
  unless new_version.match?(/^\d+\.\d+\.\d+$/)
    puts "ERROR: Version must be in format X.Y.Z (e.g., 3.3.0)"
    exit 1
  end
  
  # Update VERSION file
  version_file = File.join(File.dirname(__FILE__), '..', 'VERSION')
  File.write(version_file, new_version)
  puts "Updated VERSION file to #{new_version}"
  
  # Update all dependent files
  system("ruby #{File.join(File.dirname(__FILE__), 'update_info_version.rb')}")
  system("ruby #{File.join(File.dirname(__FILE__), 'update_website_version.rb')}")
  
  puts "\n✅ All files updated to version #{new_version}"
  puts "\nNext steps:"
  puts "1. Review changes: git diff"
  puts "2. Build and test: rake build_source"
  puts "3. Create package: rake package"
  puts "4. Deploy: cd distribution && ./deploy.sh"
end

# Command line usage
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: #{$0} <version>"
    puts "Example: #{$0} 3.4.0"
    exit 1
  end
  
  set_version(ARGV[0])
end