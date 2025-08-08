class Test
  SCHEME = 'BeHype'
  
  def self.unit
    puts "Running unit tests..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BeHypeTests")
  end

  def self.ui
    puts "Running UI tests..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BeHypeUITests")
  end

  def self.all
    puts "Running all tests..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 15'")
  end

  def self.coverage
    puts "Running tests with code coverage..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES")
  end

  def self.parallel
    puts "Running tests in parallel..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 15' -parallel-testing-enabled YES")
  end

  def self.without_building
    puts "Running tests without building..."
    system("xcodebuild test-without-building -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 15'")
  end
end