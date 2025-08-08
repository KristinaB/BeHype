require_relative 'tasks/build'
require_relative 'tasks/test'

desc "Build the iOS app for debug"
task :build do
  Build.debug
end

desc "Build the iOS app for release"
task :build_release do
  Build.release
end

desc "Run unit tests"
task :test do
  Test.unit
end

desc "Run UI tests"
task :test_ui do
  Test.ui
end

desc "Run all tests"
task :test_all do
  Test.all
end

desc "Clean build artifacts"
task :clean do
  Build.clean
end

desc "Build Rust SDK"
task :build_rust do
  Build.rust_sdk
end

desc "Generate Swift bindings from Rust"
task :build_swift_bindings do
  Build.swift_bindings
end

desc "Update iOS project with latest SDK files"
task :update_sdk do
  Build.update_ios_sdk
end

desc "Full Rust SDK build pipeline"
task :build_full_rust do
  Build.full_rust_build
end

task default: :build