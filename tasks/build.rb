class Build
  SCHEME = 'BeHype'
  RUST_DIR = 'source_project/rust'
  
  def self.debug
    puts "Building #{SCHEME} for debug..."
    system("xcodebuild -scheme #{SCHEME} -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build")
  end

  def self.release
    puts "Building #{SCHEME} for release..."
    system("xcodebuild -scheme #{SCHEME} -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16' build")
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
    system("xcodebuild -scheme #{SCHEME} -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -A 5 -B 5 'error:'")
  end

  def self.rust_sdk
    puts "Building Rust SDK..."
    Dir.chdir(RUST_DIR) do
      system("cargo build --release")
    end
  end

  def self.swift_bindings
    puts "Generating Swift bindings..."
    Dir.chdir(RUST_DIR) do
      system("cargo swift package --platforms ios macos")
    end
  end

  def self.update_ios_sdk
    puts "Updating iOS SDK files..."
    
    # Copy framework
    system("cp -r #{RUST_DIR}/HyperliquidSdkSwift/RustFramework.xcframework BeHype/Frameworks/")
    
    # Copy Swift bindings
    system("cp -r #{RUST_DIR}/HyperliquidSdkSwift/Sources/HyperliquidSdkSwift/* BeHype/HyperliquidSDK/")
    
    # Copy main SDK wrapper
    system("cp source_project/Sources/HyperliquidSwiftSDK/HyperliquidSwiftSDK.swift BeHype/HyperliquidSDK/")
    
    puts "✅ iOS SDK files updated"
  end

  def self.full_rust_build
    puts "🦀 Full Rust build pipeline..."
    rust_sdk
    swift_bindings
    update_ios_sdk
    puts "✅ Rust SDK build complete"
  end
end