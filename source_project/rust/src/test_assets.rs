use hyperliquid_rust_sdk::{BaseUrl, InfoClient};
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🧪 Testing Hyperliquid Available Assets...");
    
    // Create InfoClient
    let info = InfoClient::new(None, Some(BaseUrl::Mainnet)).await?;
    println!("✅ InfoClient created successfully");
    
    // Get regular meta (perpetuals)
    println!("\n📊 Perpetual Assets:");
    let meta = info.meta().await?;
    println!("Total perpetual assets: {}", meta.universe.len());
    for (i, asset) in meta.universe.iter().take(10).enumerate() {
        println!("  {}: {} (sz_decimals: {})", i, asset.name, asset.sz_decimals);
    }
    
    // Get spot meta
    println!("\n📊 Spot Assets:");
    let spot_meta = info.spot_meta().await?;
    println!("Total spot tokens: {}", spot_meta.tokens.len());
    println!("Total spot universe: {}", spot_meta.universe.len());
    
    // Build token index map
    let token_map: std::collections::HashMap<usize, String> = spot_meta.tokens
        .iter()
        .map(|t| (t.index, t.name.clone()))
        .collect();
    
    println!("\nSpot tokens:");
    for token in spot_meta.tokens.iter().take(10) {
        println!("  {}: {} (index: {})", token.index, token.name, token.index);
    }
    
    println!("\nSpot trading pairs:");
    let unknown = "Unknown".to_string();
    for (i, asset) in spot_meta.universe.iter().take(10).enumerate() {
        let token1_name = token_map.get(&asset.tokens[0]).unwrap_or(&unknown);
        let token2_name = token_map.get(&asset.tokens[1]).unwrap_or(&unknown);
        let pair_name = format!("{}/{}", token1_name, token2_name);
        println!("  {}: {} (tokens: {} + {})", i, pair_name, asset.tokens[0], asset.tokens[1]);
    }
    
    // Test candles on a few spot pairs
    println!("\n🧪 Testing candles on spot pairs...");
    let end_time = chrono::Utc::now().timestamp() as u64 * 1000;
    let start_time = end_time - (12 * 60 * 60 * 1000); // 12 hours ago
    
    for (_i, asset) in spot_meta.universe.iter().take(3).enumerate() {
        let token1_name = token_map.get(&asset.tokens[0]).unwrap_or(&unknown);
        let token2_name = token_map.get(&asset.tokens[1]).unwrap_or(&unknown);
        let pair_name = format!("{}/{}", token1_name, token2_name);
        
        println!("Testing candles for spot pair: {}", pair_name);
        match info.candles_snapshot(pair_name.clone(), "1h".to_string(), start_time, end_time).await {
            Ok(candles) => {
                println!("  ✅ SUCCESS: {} candles", candles.len());
                if !candles.is_empty() {
                    let last = &candles[candles.len() - 1];
                    println!("  📈 Latest: open={}, close={}", last.open, last.close);
                }
            }
            Err(e) => {
                println!("  ❌ FAILED: {}", e);
            }
        }
        
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
    }
    
    println!("\n🏁 Asset discovery complete!");
    Ok(())
}