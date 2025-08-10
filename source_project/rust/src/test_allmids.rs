use hyperliquid_sdk_swift::HyperliquidClient;

fn main() {
    println!("🔍 Testing getAllMids method...");
    println!("{}", "=".repeat(50));
    
    let client = HyperliquidClient::new();
    let mids = client.get_all_mids();
    
    println!("📊 getAllMids returned {} items:", mids.len());
    for (i, price_info) in mids.iter().enumerate() {
        println!("  {}: {} = {}", i + 1, price_info.coin, price_info.price);
    }
    
    println!("\n💰 Testing get_btc_price method...");
    let btc_price = client.get_btc_price();
    println!("BTC Price: {}", btc_price);
    
    println!("\n✨ Test complete!");
}