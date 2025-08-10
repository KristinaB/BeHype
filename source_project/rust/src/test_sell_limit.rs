use hyperliquid_sdk_swift::HyperliquidClient;

fn main() {
    println!("🔧 [DEBUG] Testing Sell Limit Order with Rust SDK");
    println!("=================================================");

    // Load private key from environment or file
    let private_key = match std::fs::read_to_string("private-key.key") {
        Ok(key) => key.trim().to_string(),
        Err(_) => {
            println!("❌ [ERROR] Could not read private-key.key");
            return;
        }
    };

    println!("✅ [DEBUG] Private key loaded");
    
    // Create wallet client
    let wallet_client = HyperliquidClient::new_with_wallet(private_key);
    println!("✅ [DEBUG] Wallet client created");

    // Test parameters from failing order
    let btc_amount_original = "0.0000899371";
    let btc_amount_rounded = "0.00009"; // Round to 5 decimals
    let limit_price = "118163.50";

    println!("\n📊 [DEBUG] Testing parameters:");
    println!("  • Original BTC amount: {}", btc_amount_original);
    println!("  • Rounded BTC amount: {}", btc_amount_rounded);
    println!("  • Limit price: ${}", limit_price);

    // Test 1: Original precision (should fail)
    println!("\n🧪 [TEST 1] Testing with original precision (10 decimals):");
    let result1 = wallet_client.place_btc_sell_order(btc_amount_original.to_string(), limit_price.to_string());
    println!("Result: success={}, message='{}'", result1.success, result1.message);
    if let Some(order_id) = result1.order_id {
        println!("Order ID: {}", order_id);
    }

    // Test 2: Rounded precision (should work)
    println!("\n🧪 [TEST 2] Testing with rounded precision (5 decimals):");
    let result2 = wallet_client.place_btc_sell_order(btc_amount_rounded.to_string(), limit_price.to_string());
    println!("Result: success={}, message='{}'", result2.success, result2.message);
    if let Some(order_id) = result2.order_id {
        println!("Order ID: {}", order_id);
    }

    // Test 3: Check current market price
    println!("\n📈 [DEBUG] Checking current market price:");
    let market_data = wallet_client.get_all_mids();
    println!("Market data retrieved - {} pairs found", market_data.len());
    for price_info in market_data.iter().take(3) {
        println!("  • {}: ${}", price_info.coin, price_info.price);
        if price_info.coin == "@142" {
            println!("  ✅ Found @142 (BTC/USDC) at ${}", price_info.price);
        }
    }

    // Test 4: Try different asset formats
    println!("\n🎯 [TEST 4] Testing direct limit order with explicit parameters:");
    let result4 = wallet_client.place_limit_order(
        "@142".to_string(),      // asset
        false,                   // is_buy = false (sell)
        btc_amount_rounded.to_string(), // size
        limit_price.to_string(), // price
        "Gtc".to_string()       // time_in_force
    );
    println!("Direct limit order result: success={}, message='{}'", result4.success, result4.message);
    if let Some(order_id) = result4.order_id {
        println!("Order ID: {}", order_id);
    }

    println!("\n✅ [DEBUG] All tests completed!");
}