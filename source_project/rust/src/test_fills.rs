use ethers::types::H160;
use std::time::{SystemTime, UNIX_EPOCH};

#[path = "lib.rs"]
mod lib;
use lib::HyperliquidClient;

fn main() {
    // Test address with known fill
    let address = "0xa07d3500373300E7f4e13c440c3A0Ae9Ad5BB7C7";
    
    // Calculate time range - last 30 days 
    let current_time = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64;
    
    let start_time = current_time - (30 * 24 * 60 * 60 * 1000); // 30 days ago
    let end_time = Some(current_time);
    
    println!("Testing user_fills_by_time for address: {}", address);
    println!("Time range: {} to {:?}", start_time, end_time);
    
    // Create client
    let client = HyperliquidClient::new();
    
    // Get fills
    let fills = client.get_user_fills_by_time(address.to_string(), start_time, end_time);
    
    println!("\nFound {} fills:", fills.len());
    
    for fill in fills.iter() {
        println!("\n--- Fill ---");
        println!("  Coin: {}", fill.coin);
        println!("  Side: {} ({})", fill.side, fill.dir);
        println!("  Price: {}", fill.px);
        println!("  Size: {}", fill.sz);
        println!("  Time: {}", fill.time);
        println!("  Order ID: {}", fill.oid);
        println!("  Hash: {}", fill.hash);
        println!("  Closed PnL: {}", fill.closed_pnl);
        println!("  Start Position: {}", fill.start_position);
        println!("  Crossed: {}", fill.crossed);
        if let Some(fee) = &fill.fee {
            println!("  Fee: {}", fee);
        }
        if let Some(fee_token) = &fill.fee_token {
            println!("  Fee Token: {}", fee_token);
        }
        if let Some(tid) = fill.tid {
            println!("  Trade ID: {}", tid);
        }
    }
}