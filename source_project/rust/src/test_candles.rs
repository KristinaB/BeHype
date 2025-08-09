use hyperliquid_rust_sdk::{BaseUrl, InfoClient};
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🧪 Testing Hyperliquid Candles API...");
    
    // Create InfoClient
    let info = InfoClient::new(None, Some(BaseUrl::Mainnet)).await?;
    println!("✅ InfoClient created successfully");
    
    // Test different coins and parameters
    let test_cases = vec![
        // (coin, interval, hours_back, description)
        ("BTC", "1h", 24, "BTC perpetual"),
        ("@142", "1h", 24, "BTC/USDC spot (index 142)"),
        ("ETH", "1h", 12, "ETH perpetual"),
        ("PURR", "1h", 12, "PURR perpetual"),
        ("PURR/USDC", "1h", 12, "PURR/USDC spot pair"),
    ];
    
    for (coin, interval, hours_back, description) in test_cases {
        println!("\n📊 Testing candles for {} ({}) with {} interval, {} hours back...", coin, description, interval, hours_back);
        
        let end_time = chrono::Utc::now().timestamp() as u64 * 1000; // milliseconds
        let start_time = end_time - (hours_back * 60 * 60 * 1000); // hours_back ago
        
        println!("   Start time: {} ({})", start_time, chrono::DateTime::from_timestamp((start_time / 1000) as i64, 0).unwrap());
        println!("   End time: {} ({})", end_time, chrono::DateTime::from_timestamp((end_time / 1000) as i64, 0).unwrap());
        
        match info.candles_snapshot(coin.to_string(), interval.to_string(), start_time, end_time).await {
            Ok(candles) => {
                println!("   ✅ SUCCESS: Retrieved {} candles", candles.len());
                if !candles.is_empty() {
                    let first = &candles[0];
                    let last = &candles[candles.len() - 1];
                    println!("   📈 First candle: {} open={}, close={}, high={}, low={}", 
                             first.coin, first.open, first.close, first.high, first.low);
                    println!("   📈 Last candle:  {} open={}, close={}, high={}, low={}", 
                             last.coin, last.close, last.close, last.high, last.low);
                }
            }
            Err(e) => {
                println!("   ❌ FAILED: {}", e);
            }
        }
        
        // Small delay between requests to be respectful
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
    }
    
    println!("\n🏁 Testing complete!");
    Ok(())
}