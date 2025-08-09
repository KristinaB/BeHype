uniffi::setup_scaffolding!();

use hyperliquid_rust_sdk::{BaseUrl, InfoClient, ExchangeClient, ClientOrderRequest, ClientOrder, ClientLimit, ExchangeResponseStatus, ExchangeDataStatus};
use ethers::signers::{LocalWallet, Signer};
use std::sync::Arc;
use tokio::runtime::Runtime;

#[derive(uniffi::Object)]
pub struct HyperliquidClient {
    info: Arc<InfoClient>,
    exchange: Option<Arc<ExchangeClient>>,
    runtime: Arc<Runtime>,
}

#[uniffi::export]
impl HyperliquidClient {
    #[uniffi::constructor]
    pub fn new() -> Self {
        let runtime = Arc::new(Runtime::new().expect("Failed to create runtime"));
        let info = runtime.block_on(async {
            InfoClient::new(None, Some(BaseUrl::Mainnet))
                .await
                .expect("Failed to create InfoClient")
        });
        
        Self {
            info: Arc::new(info),
            exchange: None,
            runtime,
        }
    }
    
    pub fn get_exchange_meta(&self) -> ExchangeMeta {
        let info = self.info.clone();
        let meta = self.runtime.block_on(async move {
            info.meta().await.expect("Failed to get meta")
        });
        
        let assets: Vec<AssetInfo> = meta.universe.iter()
            .take(10)
            .map(|asset| AssetInfo {
                name: asset.name.clone(),
                sz_decimals: asset.sz_decimals as i32,
            })
            .collect();
        
        ExchangeMeta {
            total_assets: meta.universe.len() as i32,
            assets,
        }
    }
    
    pub fn get_all_mids(&self) -> Vec<PriceInfo> {
        let info = self.info.clone();
        let all_mids = self.runtime.block_on(async move {
            info.all_mids().await.expect("Failed to get mids")
        });
        
        all_mids.iter()
            .take(10)
            .map(|(coin, price)| PriceInfo {
                coin: coin.clone(),
                price: price.clone(),
            })
            .collect()
    }
    
    pub fn get_l2_orderbook(&self, coin: String) -> OrderbookData {
        let info = self.info.clone();
        let l2_data = self.runtime.block_on(async move {
            info.l2_snapshot(coin).await.expect("Failed to get L2 snapshot")
        });
        
        let bids: Vec<OrderLevel> = l2_data.levels[0].iter()
            .take(5)
            .map(|bid| OrderLevel {
                price: bid.px.clone(),
                size: bid.sz.clone(),
            })
            .collect();
            
        let asks: Vec<OrderLevel> = l2_data.levels[1].iter()
            .take(5)
            .map(|ask| OrderLevel {
                price: ask.px.clone(),
                size: ask.sz.clone(),
            })
            .collect();
        
        OrderbookData { bids, asks }
    }
    
    #[uniffi::constructor]
    pub fn new_with_wallet(private_key: String) -> Self {
        let runtime = Arc::new(Runtime::new().expect("Failed to create runtime"));
        let (info, exchange) = runtime.block_on(async {
            let wallet: LocalWallet = private_key.parse().expect("Invalid private key");
            
            let info = InfoClient::new(None, Some(BaseUrl::Mainnet))
                .await
                .expect("Failed to create InfoClient");
                
            let exchange = ExchangeClient::new(None, wallet, Some(BaseUrl::Mainnet), None, None)
                .await
                .expect("Failed to create ExchangeClient");
            
            (info, exchange)
        });
        
        Self {
            info: Arc::new(info),
            exchange: Some(Arc::new(exchange)),
            runtime,
        }
    }
    
    pub fn get_spot_meta(&self) -> Vec<String> {
        let info = self.info.clone();
        let spot_meta = self.runtime.block_on(async move {
            info.spot_meta().await.expect("Failed to get spot meta")
        });
        
        // Build the index to name map for tokens
        let index_to_name: std::collections::HashMap<usize, String> = spot_meta
            .tokens
            .iter()
            .map(|info| (info.index, info.name.clone()))
            .collect();
        
        // Get ALL spot pairs to find BTC
        let mut pairs = Vec::new();
        for asset in spot_meta.universe.iter() {
            if let (Some(token1), Some(token2)) = (
                index_to_name.get(&asset.tokens[0]),
                index_to_name.get(&asset.tokens[1])
            ) {
                pairs.push(format!("{}/{}", token1, token2));
            }
        }
        pairs
    }
    
    pub fn get_token_balances(&self, address: String) -> Vec<TokenBalance> {
        let info = self.info.clone();
        let balances = self.runtime.block_on(async move {
            let addr = address.parse().expect("Invalid address");
            info.user_token_balances(addr).await.expect("Failed to get balances")
        });
        
        balances.balances.iter()
            .map(|balance| TokenBalance {
                coin: balance.coin.clone(),
                total: balance.total.clone(),
                hold: balance.hold.clone(),
            })
            .collect()
    }
    
    pub fn swap_usdc_to_btc(&self, usdc_amount: String) -> SwapResult {
        let exchange = match &self.exchange {
            Some(ex) => ex.clone(),
            None => {
                return SwapResult {
                    success: false,
                    message: "No wallet configured. Use new_with_wallet() constructor.".to_string(),
                    order_id: None,
                    filled_size: None,
                    avg_price: None,
                }
            }
        };
        
        let info = self.info.clone();
        let swap_result = self.runtime.block_on(async move {
            // First get current UBTC price for the spot market
            let all_mids = info.all_mids().await
                .map_err(|e| format!("Failed to get prices: {}", e))?;
            
            // Try to get UBTC price first, fall back to BTC if not found
            let btc_price: f64 = all_mids.get("UBTC/USDC")
                .or_else(|| all_mids.get("UBTC"))
                .or_else(|| all_mids.get("BTC"))
                .ok_or("UBTC/BTC price not found")?
                .parse()
                .map_err(|_| "Invalid BTC price format")?;
            
            let usdc_amount_f64: f64 = usdc_amount.parse()
                .map_err(|_| "Invalid USDC amount format")?;
            
            // BTC has 5 decimals precision, calculate and round appropriately
            let btc_size_raw = usdc_amount_f64 / btc_price;
            // Round to 5 decimal places for BTC
            let btc_size = (btc_size_raw * 100000.0).round() / 100000.0;
            
            // Ensure minimum order size (0.00001 BTC minimum)
            if btc_size < 0.00001 {
                return Err(format!("Order size too small: {} BTC", btc_size));
            }
            
            // Create spot buy order for UBTC/USDC spot pair
            // Round price to reasonable tick size (try $10 for high-value assets)
            let tick_size = 10.0;
            let limit_price_raw = btc_price * 1.01; // 1% slippage
            let limit_price = (limit_price_raw / tick_size).round() * tick_size;
            
            let order = ClientOrderRequest {
                asset: "UBTC/USDC".to_string(),  // Spot BTC trading pair
                is_buy: true,
                reduce_only: false,
                limit_px: limit_price, // Price rounded to tick size with slippage
                sz: btc_size,
                cloid: None,
                order_type: ClientOrder::Limit(ClientLimit {
                    tif: "Ioc".to_string(), // Immediate or Cancel for market-like behavior
                }),
            };
            
            let response = exchange.order(order, None).await
                .map_err(|e| format!("Failed to place order: {}", e))?;
            
            match response {
                ExchangeResponseStatus::Ok(resp) => {
                    if let Some(data) = resp.data {
                        if let Some(status) = data.statuses.first() {
                            match status {
                                ExchangeDataStatus::Filled(order) => Ok((
                                    true,
                                    format!("Order filled successfully"),
                                    Some(order.oid),
                                    Some(order.total_sz.clone()),
                                    Some(order.avg_px.clone()),
                                )),
                                ExchangeDataStatus::Resting(order) => Ok((
                                    true,
                                    format!("Order placed and resting"),
                                    Some(order.oid),
                                    None,
                                    None,
                                )),
                                _ => Err(format!("Unexpected order status: {:?}", status)),
                            }
                        } else {
                            Err("No order status returned".to_string())
                        }
                    } else {
                        Err("No response data".to_string())
                    }
                }
                ExchangeResponseStatus::Err(e) => Err(format!("Exchange error: {}", e)),
            }
        });
        
        match swap_result {
            Ok((success, message, order_id, filled_size, avg_price)) => SwapResult {
                success,
                message,
                order_id,
                filled_size,
                avg_price,
            },
            Err(e) => SwapResult {
                success: false,
                message: e,
                order_id: None,
                filled_size: None,
                avg_price: None,
            },
        }
    }
    
    pub fn get_candles_snapshot(&self, coin: String, interval: String, start_time: u64, end_time: u64) -> Vec<CandleData> {
        let info = self.info.clone();
        let candles = self.runtime.block_on(async move {
            info.candles_snapshot(coin, interval, start_time, end_time).await.expect("Failed to get candles")
        });
        
        candles.iter()
            .map(|candle| CandleData {
                time_open: candle.time_open,
                time_close: candle.time_close,
                coin: candle.coin.clone(),
                interval: candle.candle_interval.clone(),
                open: candle.open.clone(),
                close: candle.close.clone(),
                high: candle.high.clone(),
                low: candle.low.clone(),
                volume: candle.vlm.clone(),
                num_trades: candle.num_trades,
            })
            .collect()
    }
}

#[derive(uniffi::Record)]
pub struct ExchangeMeta {
    pub total_assets: i32,
    pub assets: Vec<AssetInfo>,
}

#[derive(uniffi::Record)]
pub struct AssetInfo {
    pub name: String,
    pub sz_decimals: i32,
}

#[derive(uniffi::Record)]
pub struct PriceInfo {
    pub coin: String,
    pub price: String,
}

#[derive(uniffi::Record)]
pub struct OrderbookData {
    pub bids: Vec<OrderLevel>,
    pub asks: Vec<OrderLevel>,
}

#[derive(uniffi::Record)]
pub struct OrderLevel {
    pub price: String,
    pub size: String,
}

#[derive(uniffi::Record)]
pub struct TokenBalance {
    pub coin: String,
    pub total: String,
    pub hold: String,
}

#[derive(uniffi::Record)]
pub struct SwapResult {
    pub success: bool,
    pub message: String,
    pub order_id: Option<u64>,
    pub filled_size: Option<String>,
    pub avg_price: Option<String>,
}

#[derive(uniffi::Record)]
pub struct CandleData {
    pub time_open: u64,
    pub time_close: u64,
    pub coin: String,
    pub interval: String,
    pub open: String,
    pub close: String,
    pub high: String,
    pub low: String,
    pub volume: String,
    pub num_trades: u64,
}

#[uniffi::export]
pub fn hello_hyperliquid() -> String {
    "Hello from Hyperliquid Rust SDK!".to_string()
}

#[uniffi::export]
pub fn derive_address_from_private_key(private_key: String) -> String {
    let wallet: Result<LocalWallet, _> = private_key.parse();
    match wallet {
        Ok(w) => format!("{:#x}", w.address()),
        Err(_) => "Invalid private key".to_string(),
    }
}