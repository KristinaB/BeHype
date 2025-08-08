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

task default: :build