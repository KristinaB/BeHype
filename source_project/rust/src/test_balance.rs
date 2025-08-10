use reqwest;
use serde_json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Test address that should have BTC balance
    let test_address = "0xa07d3500373300E7f4e13c440c3A0Ae9Ad5BB7C7";
    
    println!("🔍 Fetching token balances for address: {}", test_address);
    println!("{}", "=".repeat(60));
    
    // Create request body for user state
    let request_body = serde_json::json!({
        "type": "clearinghouseState",
        "user": test_address
    });
    
    // Make API request
    let client = reqwest::Client::new();
    let response = client
        .post("https://api.hyperliquid.xyz/info")
        .json(&request_body)
        .send()
        .await?;
    
    let response_text = response.text().await?;
    let state: serde_json::Value = serde_json::from_str(&response_text)?;
    
    // Parse balances from the response
    if let Some(asset_positions) = state["assetPositions"].as_array() {
        println!("📊 Asset Positions Found:");
        println!("{}", "-".repeat(60));
        
        let mut btc_found = false;
        let mut usdc_found = false;
        
        for position in asset_positions {
            if let Some(coin_obj) = position["position"]["coin"].as_object() {
                if let Some(token) = coin_obj.get("token") {
                    let token_str = token.as_str().unwrap_or("");
                    let size = position["position"]["szi"].as_str().unwrap_or("0");
                    
                    // Check for BTC position (@142 is BTC/USDC spot)
                    if token_str == "@142" || token_str == "BTC" {
                        println!("₿ BTC Position:");
                        println!("  Size: {} BTC", size);
                        
                        // Parse and check if positive
                        if let Ok(size_float) = size.parse::<f64>() {
                            if size_float > 0.0 {
                                println!("  ✅ Status: POSITIVE balance!");
                                btc_found = true;
                            } else if size_float < 0.0 {
                                println!("  ⚠️ Status: Negative (short position)");
                            } else {
                                println!("  ⚠️ Status: Zero balance");
                            }
                        }
                        
                        // Show entry price and unrealized PnL if available
                        if let Some(entry_px) = position["position"]["entryPx"].as_str() {
                            println!("  Entry Price: ${}", entry_px);
                        }
                        if let Some(unrealized_pnl) = position["position"]["unrealizedPnl"].as_str() {
                            println!("  Unrealized PnL: ${}", unrealized_pnl);
                        }
                        println!();
                    }
                }
            }
        }
        
        // Also check spot balances
        if let Some(balances) = state["crossMaintenanceMarginUsed"].as_str() {
            println!("💰 Maintenance Margin Used: ${}", balances);
        }
        
        if !btc_found {
            println!("⚠️ No BTC position found for this address");
            println!("💡 Try trading BTC/USDC spot to create a position");
        }
    }
    
    // Also fetch spot balances using a different endpoint
    println!("\n📋 Fetching Spot Token Balances:");
    println!("{}", "=".repeat(60));
    
    let spot_request = serde_json::json!({
        "type": "spotClearinghouseState", 
        "user": test_address
    });
    
    let spot_response = client
        .post("https://api.hyperliquid.xyz/info")
        .json(&spot_request)
        .send()
        .await?;
    
    let spot_text = spot_response.text().await?;
    let spot_state: serde_json::Value = serde_json::from_str(&spot_text)?;
    
    // Debug: Print the entire response structure
    println!("Debug - Full spot state response:");
    println!("{}", serde_json::to_string_pretty(&spot_state)?);
    
    if let Some(balances) = spot_state["balances"].as_array() {
        println!("\n💰 Found {} balances:", balances.len());
        for balance in balances {
            if let (Some(coin), Some(total), Some(hold)) = (
                balance["coin"].as_str(),
                balance["total"].as_str(),
                balance["hold"].as_str()
            ) {
                let total_float = total.parse::<f64>().unwrap_or(0.0);
                
                if (coin == "BTC" || coin == "UBTC") && total_float > 0.0 {
                    println!("✅ BTC Spot Balance: {} BTC (POSITIVE!)", total);
                    println!("   Hold: {} BTC", hold);
                    println!("   Entry Value: ${}", balance["entryNtl"].as_str().unwrap_or("0"));
                } else if coin == "BTC" || coin == "UBTC" {
                    println!("⚠️ BTC Spot Balance: {} BTC", total);
                } else if coin == "USDC" && total_float > 0.0 {
                    println!("💵 USDC Balance: {} USDC", total);
                    println!("   Hold: {} USDC", hold);
                } else if total_float > 0.0 {
                    println!("💎 {} Balance: {} {}", coin, total, coin);
                }
            }
        }
    } else {
        println!("⚠️ No balances array found in response");
    }
    
    // Try another method - user fills to see if they have traded BTC
    println!("\n📈 Recent BTC Trading Activity:");
    println!("{}", "=".repeat(60));
    
    let current_time = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)?
        .as_millis() as u64;
    let start_time = current_time - (7 * 24 * 60 * 60 * 1000); // 7 days ago
    
    let fills_request = serde_json::json!({
        "type": "userFillsByTime",
        "user": test_address,
        "startTime": start_time,
        "endTime": current_time
    });
    
    let fills_response = client
        .post("https://api.hyperliquid.xyz/info")
        .json(&fills_request)
        .send()
        .await?;
    
    let fills_text = fills_response.text().await?;
    let fills: serde_json::Value = serde_json::from_str(&fills_text)?;
    
    if let Some(fills_array) = fills.as_array() {
        let btc_fills: Vec<_> = fills_array
            .iter()
            .filter(|f| f["coin"].as_str() == Some("@142"))
            .collect();
        
        if !btc_fills.is_empty() {
            println!("Found {} BTC/USDC trades in the last 7 days", btc_fills.len());
            
            // Show last 3 trades
            for (i, fill) in btc_fills.iter().take(3).enumerate() {
                if let (Some(side), Some(sz), Some(px)) = (
                    fill["side"].as_str(),
                    fill["sz"].as_str(), 
                    fill["px"].as_str()
                ) {
                    let action = if side == "B" { "BUY" } else { "SELL" };
                    println!("  Trade {}: {} {} at ${}", i+1, action, sz, px);
                }
            }
        } else {
            println!("No recent BTC trades found");
        }
    }
    
    println!("\n✨ Balance check complete!");
    
    Ok(())
}