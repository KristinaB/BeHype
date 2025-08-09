class Test
  SCHEME = 'BeHype'
  
  def self.unit
    puts "Running unit tests..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeHypeTests")
  end

  def self.ui
    puts "Running UI tests..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeHypeUITests")
  end

  def self.ui_flow
    puts "Running complete UI flow test..."
    system("xcodebuild test -scheme #{SCHEME} -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BeHypeUITests/BeHypeUITests/testCompleteUIFlow")
  end
end