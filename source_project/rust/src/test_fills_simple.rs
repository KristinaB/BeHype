use std::time::{SystemTime, UNIX_EPOCH};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
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
    
    // Make raw API request for user fills by time
    let request_body = serde_json::json!({
        "type": "userFillsByTime",
        "user": address,
        "startTime": start_time,
        "endTime": end_time
    });
    
    println!("\nRequest body: {}", serde_json::to_string_pretty(&request_body)?);
    
    // Use reqwest to make the API call
    let client = reqwest::Client::new();
    let response = client
        .post("https://api.hyperliquid.xyz/info")
        .json(&request_body)
        .send()
        .await?;
    
    let fills: Vec<serde_json::Value> = response.json().await?;
    
    println!("\nFound {} fills:", fills.len());
    
    for fill in fills.iter() {
        println!("\n--- Fill ---");
        println!("  Coin: {}", fill["coin"].as_str().unwrap_or(""));
        println!("  Side: {} ({})", fill["side"].as_str().unwrap_or(""), fill["dir"].as_str().unwrap_or(""));
        println!("  Price: {}", fill["px"].as_str().unwrap_or(""));
        println!("  Size: {}", fill["sz"].as_str().unwrap_or(""));
        println!("  Time: {}", fill["time"].as_u64().unwrap_or(0));
        println!("  Order ID: {}", fill["oid"].as_u64().unwrap_or(0));
        println!("  Hash: {}", fill["hash"].as_str().unwrap_or(""));
        println!("  Closed PnL: {}", fill["closedPnl"].as_str().unwrap_or(""));
        println!("  Start Position: {}", fill["startPosition"].as_str().unwrap_or(""));
        println!("  Crossed: {}", fill["crossed"].as_bool().unwrap_or(false));
        if let Some(fee) = fill["fee"].as_str() {
            println!("  Fee: {}", fee);
        }
        if let Some(fee_token) = fill["feeToken"].as_str() {
            println!("  Fee Token: {}", fee_token);
        }
        if let Some(tid) = fill["tid"].as_u64() {
            println!("  Trade ID: {}", tid);
        }
    }
    
    Ok(())
}