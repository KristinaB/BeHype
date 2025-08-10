use hyperliquid_sdk_swift::HyperliquidClient;

fn main() {
    println!("🔧 [DEBUG] Testing Price Rounding for Sell Limit Orders");
    println!("====================================================");

    // Load private key
    let private_key = match std::fs::read_to_string("private-key.key") {
        Ok(key) => key.trim().to_string(),
        Err(_) => {
            println!("❌ [ERROR] Could not read private-key.key");
            return;
        }
    };

    let wallet_client = HyperliquidClient::new_with_wallet(private_key);

    // Test with properly rounded values based on market data
    // Market price was $118144.5, so tick size appears to be $0.5
    println!("\n🧪 [TEST] Using tick-size aligned prices:");
    
    let test_cases = vec![
        ("0.00009", "118163.5"),  // Rounded to nearest $0.5
        ("0.00009", "118164.0"),  // Even dollar amount
        ("0.00009", "118144.5"),  // Current market price
    ];
    
    for (btc_amount, price) in test_cases {
        println!("\n📊 Testing BTC: {}, Price: ${}", btc_amount, price);
        let result = wallet_client.place_btc_sell_order(btc_amount.to_string(), price.to_string());
        println!("  Result: success={}, message='{}'", result.success, result.message);
        
        // If successful, we found the right format!
        if result.success {
            println!("  ✅ SUCCESS! This combination works!");
            if let Some(order_id) = result.order_id {
                println!("  📋 Order ID: {}", order_id);
            }
            break;
        } else {
            println!("  ❌ Failed: {}", result.message);
        }
    }

    println!("\n✅ Price rounding test complete!");
}