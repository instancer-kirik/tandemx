import gleam/option.{type Option}

pub type Network {
  Ethereum
  Polygon
  Arbitrum
  Optimism
  BinanceSmartChain
}

pub type WalletType {
  EOA
  SmartContract
  MultiSig
}

pub type WalletStatus {
  WalletActive
  WalletLocked
  WalletArchived
}

pub type DeFiWallet {
  DeFiWallet(
    id: String,
    name: String,
    address: String,
    network: Network,
    wallet_type: WalletType,
    status: WalletStatus,
    balance: Float,
    tokens: List(Token),
    nfts: List(NFT),
    connected_at: String,
    last_activity: String,
  )
}

pub type Token =
  #(
    String,
    String,
    String,
    Int,
    Float,
    Float,
    Int,
    // address
    // symbol
    // name
    // decimals
    // balance
    // price_usd
    // chain_id
  )

pub type NFT =
  #(
    String,
    String,
    String,
    Option(
      String,
      // contract_address
      // token_id
      // name
    ),
    Option(
      String,
      // description
    ),
    Option(
      String,
      // image_url
    ),
    // metadata
  )

pub type DeFiProtocol {
  DeFiProtocol(
    id: String,
    name: String,
    network: Network,
    tvl_usd: Float,
    apy: Float,
    risk_level: RiskLevel,
    supported_tokens: List(String),
    status: ProtocolStatus,
  )
}

pub type RiskLevel {
  Low
  Medium
  High
}

pub type ProtocolStatus {
  ProtocolActive
  ProtocolPaused
  ProtocolDeprecated
}

pub type Position {
  Position(
    id: String,
    protocol_id: String,
    wallet_address: String,
    position_type: PositionType,
    token_address: String,
    amount: Float,
    value_usd: Float,
    apy: Float,
    opened_at: String,
    last_updated: String,
  )
}

pub type PositionType {
  Lending
  Borrowing
  LiquidityProviding
  Staking
  Farming
}

pub type DeFiTransaction =
  #(
    String,
    String,
    String,
    Float,
    Float,
    Float,
    TransactionStatus,
    String,
    Network,
    // hash
    // from_address
    // to_address
    // value
    // gas_price
    // gas_used
    // timestamp
  )

pub type TransactionStatus {
  Pending
  Confirmed
  Failed
}

pub type DeFiAlert {
  DeFiAlert(
    id: String,
    wallet_address: String,
    alert_type: AlertType,
    threshold: Float,
    current_value: Float,
    triggered_at: String,
  )
}

pub type AlertType {
  LowBalance
  HighGas
  PriceMovement
  LiquidationRisk
  PositionHealth
}
