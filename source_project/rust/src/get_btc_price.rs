use reqwest;
use serde_json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("💰 Fetching latest BTC/USDC mid price...");
    println!("{}", "=".repeat(50));

    // Create request body for all mids
    let request_body = serde_json::json!({
        "type": "allMids"
    });

    // Make API request
    let client = reqwest::Client::new();
    let response = client
        .post("https://api.hyperliquid.xyz/info")
        .json(&request_body)
        .send()
        .await?;

    let response_text = response.text().await?;
    let all_mids: serde_json::Value = serde_json::from_str(&response_text)?;

    // Look for BTC/USDC mid price
    if let Some(mids_map) = all_mids.as_object() {
        // Try different BTC variants
        let btc_variants = ["@142", "BTC", "UBTC", "BTC/USDC", "UBTC/USDC"];

        let mut btc_price_found = false;

        for variant in &btc_variants {
            if let Some(price_value) = mids_map.get(*variant) {
                if let Some(price_str) = price_value.as_str() {
                    if let Ok(price) = price_str.parse::<f64>() {
                        println!("₿ BTC Price ({}):", variant);
                        println!("  Mid Price: ${:.2}", price);
                        println!("  Raw Value: {}", price_str);

                        // Calculate some useful metrics
                        if price > 0.0 {
                            let one_btc_cost = price;
                            let one_thousand_usd_btc = 1000.0 / price;

                            println!("  📊 Quick Calculations:");
                            println!("    1 BTC costs: ${:.2}", one_btc_cost);
                            println!("    $1,000 buys: {:.6} BTC", one_thousand_usd_btc);
                        }

                        println!();
                        btc_price_found = true;
                    }
                }
            }
        }

        if !btc_price_found {
            println!("⚠️ BTC price not found in available markets");
            println!("📋 Available markets (first 20):");

            let mut count = 0;
            for (key, value) in mids_map.iter() {
                if count >= 20 {
                    break;
                }
                if let Some(price_str) = value.as_str() {
                    println!("  {}: ${}", key, price_str);
                }
                count += 1;
            }

            if mids_map.len() > 20 {
                println!("  ... and {} more markets", mids_map.len() - 20);
            }
        }
    } else {
        println!("❌ Failed to parse mids response");
        println!("Raw response: {}", response_text);
    }

    println!("✨ Price fetch complete!");

    Ok(())
}
