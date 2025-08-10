use hyperliquid_sdk_swift::HyperliquidClient;

fn main() {
    println!("🚀 [REAL SELL] Market Sell Order Test");
    println!("====================================");

    // Load private key
    let private_key = match std::fs::read_to_string("private-key.key") {
        Ok(key) => key.trim().to_string(),
        Err(_) => {
            println!("❌ [ERROR] Could not read private-key.key");
            return;
        }
    };

    let wallet_client = HyperliquidClient::new_with_wallet(private_key);
    
    // User's exact balance
    let btc_balance = "0.0000899371";
    
    println!("💰 [INFO] Your BTC balance: {}", btc_balance);
    
    // Get current market price first
    println!("\n📈 [STEP 1] Getting current BTC market price...");
    let market_data = wallet_client.get_all_mids();
    
    let mut btc_price: f64 = 0.0;
    for price_info in market_data.iter() {
        if price_info.coin == "@142" {
            btc_price = price_info.price.parse().unwrap_or(0.0);
            println!("✅ Current BTC/USDC market price: ${}", btc_price);
            break;
        }
    }
    
    if btc_price == 0.0 {
        println!("❌ [ERROR] Could not get BTC market price");
        return;
    }
    
    // Apply our iOS app rounding logic
    println!("\n🔧 [STEP 2] Applying rounding for compliance...");
    
    // Round BTC to 5 decimals
    let btc_amount_f64: f64 = btc_balance.parse().unwrap();
    let rounded_btc = (btc_amount_f64 * 100000.0).round() / 100000.0;
    let rounded_btc_str = format!("{:.5}", rounded_btc);
    
    // Round price to $1.00 tick size
    let rounded_price = btc_price.round();
    let rounded_price_str = format!("{:.0}", rounded_price);
    
    println!("  • BTC amount: {} → {}", btc_balance, rounded_btc_str);
    println!("  • Price: ${} → ${}", btc_price, rounded_price_str);
    
    let expected_usd = rounded_btc * rounded_price;
    println!("  • Expected proceeds: ${:.2}", expected_usd);
    
    // Execute the real sell order
    println!("\n🔄 [STEP 3] Placing REAL sell limit order...");
    println!("⚠️  [WARNING] This will place an actual order on Hyperliquid mainnet!");
    
    let result = wallet_client.place_btc_sell_order(rounded_btc_str.clone(), rounded_price_str.clone());
    
    println!("\n📋 [RESULT] Order execution result:");
    println!("  • Success: {}", result.success);
    println!("  • Message: '{}'", result.message);
    
    if result.success {
        println!("  ✅ ORDER PLACED SUCCESSFULLY! 🎉");
        if let Some(order_id) = result.order_id {
            println!("  📊 Order ID: {}", order_id);
        }
        if let Some(filled_size) = result.filled_size {
            println!("  📈 Filled Size: {}", filled_size);
        }
        if let Some(avg_price) = result.avg_price {
            println!("  💵 Average Price: ${}", avg_price);
        }
        
        println!("\n🎯 Your sell order is now active on Hyperliquid!");
        println!("   • Selling {} BTC at ${}", rounded_btc_str, rounded_price_str);
        println!("   • Order will fill when market reaches your price");
        println!("   • Check your BeHype app for order status updates");
        
    } else {
        println!("  ❌ Order failed: {}", result.message);
        println!("\n🔍 Common failure reasons:");
        println!("   • Insufficient balance");
        println!("   • Price/amount formatting issues"); 
        println!("   • Network connectivity");
        println!("   • API rate limiting");
    }
    
    println!("\n✅ Real sell order test complete!");
}