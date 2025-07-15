#!/usr/bin/env ruby

require_relative 'get_version'

def update_info_version
  version_parts = parse_version(get_version)
  info_file = File.join(File.dirname(__FILE__), '..', 'src', 'Info.lua')
  
  if !File.exist?(info_file)
    puts "ERROR: Info.lua file not found: #{info_file}"
    exit 1
  end
  
  content = File.read(info_file)
  
  # Update the VERSION table in Lua format
  version_line = "\tVERSION = { major = #{version_parts[:major]}, minor = #{version_parts[:minor]}, revision = #{version_parts[:revision]}, build = 1, },"
  content.gsub!(/\tVERSION = \{[^}]+\},/, version_line)
  
  File.write(info_file, content)
  puts "Updated Info.lua version to #{version_parts[:full]}"
end

# If called directly, run the update
if __FILE__ == $0
  update_info_version
end