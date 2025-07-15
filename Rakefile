require 'rake/clean'
require_relative 'scripts/get_version'

# Get version from centralized VERSION file
VERSION = get_version
VERSION_PARTS = parse_version(VERSION)

# Updated for Gemini AI Image Tagger - Lightroom Classic 2024
LUAC = "/opt/homebrew/bin/luac"  # Use installed Lua 5.4.8
ZIP = "zip"

BUILD_DIR = "build"
PLUGIN_DIR = File.join(BUILD_DIR, "gemini-lr-tagimg.lrplugin")
DIST_DIR = "dist"

SOURCE_FILES = FileList[ File.join("src", "*.lua") ]
RESOURCE_FILES = FileList[ File.join("src", "*.png") ]
TRANSLATION_FILES = FileList[ File.join("src", "TranslatedStrings_*.txt") ]
README_FILES = FileList[ "README.md", "LICENSE" ]
TARGET_FILES = SOURCE_FILES.pathmap(File.join(PLUGIN_DIR, "%f")) + README_FILES.pathmap(File.join(PLUGIN_DIR, "%f"))
PACKAGE_FILE = File.join(DIST_DIR, "gemini-lr-tagimg-v#{VERSION}.zip")

task :default => [ :compile, :package ]

desc "Show version information"
task :version do
  puts "Gemini AI Image Tagger v#{VERSION} - Updated for Lightroom Classic 2024"
  puts "SDK Version: 13.0 (minimum 10.0)"
  puts "Google Gemini AI: Latest API with 13 preset prompts"
end

desc "Update all files with current version from VERSION file"
task :update_version do
  puts "Updating all files to version #{VERSION}..."
  sh "ruby scripts/update_info_version.rb"
  sh "ruby scripts/update_website_version.rb"
  puts "All version references updated to #{VERSION}"
end

desc "Build plugin using source files (no compilation)"
task :build_source => [ PLUGIN_DIR ] do
  puts "Building plugin with source files (no compilation)..."

  # Copy source files directly
  SOURCE_FILES.each do |src|
    tgt = src.pathmap(File.join(PLUGIN_DIR, "%f"))
    cp src, tgt
    puts "Copied: #{src} -> #{tgt}"
  end

  # Copy resource, translation, and readme files
  (RESOURCE_FILES + TRANSLATION_FILES + README_FILES).each do |src|
    tgt = src.pathmap(File.join(PLUGIN_DIR, "%f"))
    cp src, tgt
    puts "Copied: #{src} -> #{tgt}"
  end

  puts "Plugin built successfully in #{PLUGIN_DIR}"
  puts "You can now install this folder as a Lightroom plugin."
end

desc "Package plugin using source files"
task :package_source => [ :build_source, DIST_DIR ] do
  puts "Creating distribution package..."
  sh "cd #{BUILD_DIR} && #{ZIP} --recurse-paths #{File.absolute_path(PACKAGE_FILE)} #{PLUGIN_DIR.pathmap("%f")}"
  puts "Package created: #{PACKAGE_FILE}"
end

directory BUILD_DIR
CLEAN << BUILD_DIR

directory PLUGIN_DIR
CLEAN << PLUGIN_DIR

directory DIST_DIR
CLOBBER << DIST_DIR

desc "Compile source files"
task :compile => [ :test, PLUGIN_DIR ]

task :test do
  puts "Testing Lua compiler..."
  begin
    sh "#{LUAC} -v"
    puts "Lua compiler confirmed - ready for compilation"
  rescue
    puts "ERROR: Lua compiler not found at #{LUAC}!"
    puts "Please install Lua:"
    puts "  brew install lua"
    puts ""
    puts "Or if you prefer to work with source files directly,"
    puts "you can skip compilation and use the .lua files as-is."
    exit 1
  end
end

SOURCE_FILES.each do |src|
	tgt = src.pathmap(File.join(PLUGIN_DIR, "%f"))
	file tgt => src do
		sh "#{LUAC} -o #{tgt} #{src}"
	end
	CLEAN << tgt
	task :compile => tgt
	task PACKAGE_FILE => tgt
end

(RESOURCE_FILES + TRANSLATION_FILES + README_FILES).each do |src|
	tgt = src.pathmap(File.join(PLUGIN_DIR, "%f"))
	file tgt => src do
		cp src, tgt
	end
	CLEAN << tgt
	task PACKAGE_FILE => tgt
end

desc "Create distribution package file"
task :package => [ :compile, PACKAGE_FILE ]

task PACKAGE_FILE => DIST_DIR do
	sh "cd #{BUILD_DIR} && #{ZIP} --recurse-paths #{File.absolute_path(PACKAGE_FILE)} #{PLUGIN_DIR.pathmap("%f")}"
end
