class Build
  SCHEME = 'BeHype'
  
  def self.debug
    puts "Building #{SCHEME} for debug..."
    system("xcodebuild -scheme #{SCHEME} -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build")
  end

  def self.release
    puts "Building #{SCHEME} for release..."
    system("xcodebuild -scheme #{SCHEME} -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15' build")
  end

  def self.clean
    puts "Cleaning build artifacts..."
    system("xcodebuild -scheme #{SCHEME} clean")
  end

  def self.archive
    puts "Archiving #{SCHEME}..."
    system("xcodebuild -scheme #{SCHEME} -configuration Release archive -archivePath build/#{SCHEME}.xcarchive")
  end

  def self.check_errors
    puts "Checking for build errors..."
    system("xcodebuild -scheme #{SCHEME} -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | grep -A 5 -B 5 'error:'")
  end
end