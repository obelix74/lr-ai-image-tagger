#!/usr/bin/env ruby

# Read version from VERSION file
def get_version
  version_file = File.join(File.dirname(__FILE__), '..', 'VERSION')
  File.read(version_file).strip
end

def parse_version(version_string)
  parts = version_string.split('.')
  {
    major: parts[0].to_i,
    minor: parts[1].to_i,
    revision: parts[2].to_i,
    full: version_string
  }
end

# If called directly, output the version
if __FILE__ == $0
  puts get_version
end