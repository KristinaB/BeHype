# CLAUDE.md - BeHype iOS Project

## BeHype iOS Project Setup

This project integrates Hyperliquid Rust SDK into iOS. Key setup requirements:

### Xcode Manual Configuration Needed:
1. **Add Framework**: In Xcode, add `BeHype/Frameworks/RustFramework.xcframework` to "Link Binary With Libraries" in Build Phases
2. **Add Swift Files**: Add all files from `BeHype/HyperliquidSDK/` to Xcode project
3. **Add private-key.key**: Add the private key file to bundle for wallet functionality
4. **Build Settings**: Configure Framework Search Paths: `$(SRCROOT)/BeHype/Frameworks`

### Rake Tasks Available:
- `rake build` - iOS debug build
- `rake build_full_rust` - Build Rust SDK + update iOS files
- `rake build_rust` - Build Rust SDK only
- `rake update_sdk` - Copy SDK files to iOS project
- `rake test` - Run unit tests
- `rake test_ui` - Run UI tests
- `rake test_ui_flow` - Run complete UI flow test only

### App Architecture:
BeHype is a professional SwiftUI trading app with four main screens:

#### **TabView Navigation Structure:**
- **HomeView**: Portfolio overview, market data, branding, Fund Wallet functionality
- **TradeView**: Professional limit order entry for BTC/USDC spot trading 
- **TransactionsView**: Transaction history with filtering and search
- **FundWalletView**: Professional wallet funding with QR codes (modal)

#### **Design System (`BeHype/DesignSystem/`):**
- **Colors.swift**: Blue/green brand theme with dark mode glass morphism
- **Cards.swift**: Glass effect cards including MarketCardWithChart component
- **Typography.swift**: Hierarchical text styles with brand gradients
- **Buttons.swift**: Primary/secondary/icon buttons with loading states
- **TextFields.swift**: Specialized trading form inputs (amount, price, search)

#### **Services (`BeHype/Services/`):**
- **QRCodeGenerator.swift**: CoreImage-based QR code generation with BeHype branding
  - BeHype blue color replacement for black pixels
  - "BH" center logo with circular border
  - High error correction for reliable scanning
  - SwiftUI QRCodeView component with fallback placeholder

#### **Screen Details:**

**HomeView** (`BeHype/Screens/HomeView.swift`):
- BeHype branding with blue→cyan→green gradient logo
- Professional Fund Wallet button with gradient styling
- PortfolioCard components showing USDC balance and total value
- MarketCardWithChart displaying BTC/USDC price with integrated chart button
- Debug actions sheet with all original functionality

**TradeView** (`BeHype/Screens/TradeView.swift`):
- Professional order type selector (Buy/Sell with color coding)
- AmountTextField with balance display and MAX button
- PriceTextField with market price display and MARKET button  
- Real-time order summary with estimated receive amounts
- Integration with `hyperliquidService.performSwap()` for $11 orders

**TransactionsView** (`BeHype/Screens/TransactionsView.swift`):
- FilterButton array for All/Pending/Confirmed/Failed/Buys/Sells
- SearchTextField for filtering transaction details
- TransactionRow components with status badges and type icons
- Sample data generation based on `hyperliquidService.lastSwapResult`

**FundWalletView** (`BeHype/Screens/FundWalletView.swift`):
- Professional wallet funding interface with BeHype branding
- Real QR code generation with BeHype colors and "BH" center logo
- Wallet address display with monospace font and copy functionality
- Network badge showing mainnet status with warnings
- Haptic feedback on address copying with clipboard integration

**CandlestickChartView** (`BeHype/Screens/ChartView.swift`):
- Real-time BTC/USDC candlestick charts using SwiftUI Charts
- Multiple timeframes: 15m, 1h, 4h, 1d (1w removed due to data issues)
- Custom CandlestickMark components with OHLC data visualization
- Dynamic spacing algorithms and proper timestamp handling
- X-axis time labels and chart interaction features

#### **Key Features:**
- Real BTC/USDC spot trading using "@142" Hyperliquid format  
- Portfolio tracking with USDC balance and total value
- Professional limit order form with validation and estimates
- Transaction history with filtering and search capabilities
- **Wallet funding with QR codes** - professional receive interface with branded QR generation
- **Candlestick charts** - real-time BTC/USDC price charts with multiple timeframes
- **Comprehensive UI testing** - automated tests for all screens and navigation flows
- Dark mode glass morphism design with blue/green theme
- Full integration with existing Rust SDK and HyperliquidService

### Development Workflow:
- **CRITICAL: Always use rake tasks for building - NEVER run cargo or xcodebuild directly**
- **NEVER use `cargo build`, `cargo run`, or `xcodebuild` commands directly**
- **ALWAYS use the provided rake tasks for all build operations**
- Rust changes: `rake build_full_rust` then manual Xcode build
- iOS changes: `rake build` 
- SwiftUI screens integrate with existing HyperliquidService
- All trading functionality works with real Hyperliquid mainnet

### Trading Features:
- **Limit Orders**: Full buy/sell limit order functionality implemented
  - HyperliquidService has `placeLimitOrder()`, `placeBuyOrder()`, `placeSellOrder()` methods
  - TradeView supports both BTC/USDC buy and sell operations with limit prices
  - Smart execution: Real trading for $11 USDC orders, simulation for other amounts
  - Proper precision: 5 decimals for BTC, 2 decimals for USDC pairs
- **Order Types**: Buy/Sell with professional UI and validation
- **BTC Price**: Direct API fetching implemented to work around getAllMids sampling issue
- **Transaction History**: Fetches and displays user fills with filtering

### iOS Debugging Procedure:
When debugging iOS apps with missing resources or initialization issues:
1. Add comprehensive print() statements with emojis for visual clarity
2. Check Bundle.main.path() for resource files (returns nil if not in bundle)
3. Verify file reading with try? String(contentsOfFile:)
4. Check object initialization state (nil checks)
5. Add guards that attempt to fix issues (e.g., load wallet if not loaded)
6. Look at Xcode console output for debug logs
7. Common issue: Resources not added to bundle - fix in Xcode "Build Phases" → "Copy Bundle Resources"

### Testing:
- **UI Tests**: Comprehensive test suite covering all screens and navigation
- **Test Commands**: `rake test_ui` for all UI tests, `rake test_ui_flow` for main flow only
- **Screen Coverage**: Home, Trade, Transactions tabs + Chart modal functionality
- **Automated Validation**: Verifies UI elements load correctly without functional testing
- **IMPORTANT**: Never run test commands directly - always ask the user to run them and provide the output for analysis

### Claude Code Configuration:
- **Local Settings**: `.claude/settings.local.json` contains project-specific Claude Code configuration
- **Auto-approved Commands**: Pre-approved bash commands for common development tasks (git, rake, xcodebuild, etc.)
- **Tool Access**: Configured for iOS development workflow with simulator and testing tools