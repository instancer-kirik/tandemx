import components/nav
import defi/types.{
  type AlertType, type DeFiAlert, type DeFiProtocol, type DeFiTransaction,
  type DeFiWallet, type NFT, type Network, type Position, type PositionType,
  type ProtocolStatus, type RiskLevel, type Token, type TransactionStatus,
  type WalletStatus, type WalletType,
}
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    wallets: Dict(String, DeFiWallet),
    protocols: Dict(String, DeFiProtocol),
    positions: Dict(String, Position),
    transactions: Dict(String, DeFiTransaction),
    alerts: Dict(String, DeFiAlert),
    selected_wallet: Option(String),
    selected_protocol: Option(String),
    nav_open: Bool,
  )
}

pub type Msg {
  ConnectWallet(String, String, Network)
  DisconnectWallet(String)
  LockWallet(String)
  UnlockWallet(String)
  ArchiveWallet(String)
  UpdateWalletTokens(String, List(Token))
  UpdateWalletNFTs(String, List(NFT))
  SelectWallet(String)
  SelectProtocol(String)
  DepositToProtocol(String, String, String, Float)
  WithdrawFromProtocol(String, String, String, Float)
  CreatePosition(String, String, String, PositionType, Float)
  ClosePosition(String)
  SetAlertThreshold(String, AlertType, Float)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_wallet =
    DeFiWallet(
      id: "wallet1",
      name: "Main Wallet",
      address: "0x1234...5678",
      network: types.Ethereum,
      wallet_type: types.EOA,
      status: types.WalletActive,
      balance: 1.5,
      tokens: [
        Token(
          address: "0xdac17f958d2ee523a2206206994597c13d831ec7",
          symbol: "USDT",
          name: "Tether USD",
          decimals: 6,
          balance: 1000.0,
          price_usd: 1.0,
          chain_id: 1,
        ),
        Token(
          address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
          symbol: "WBTC",
          name: "Wrapped Bitcoin",
          decimals: 8,
          balance: 0.05,
          price_usd: 65_000.0,
          chain_id: 1,
        ),
      ],
      nfts: [],
      connected_at: "2024-03-20T10:00:00Z",
      last_activity: "2024-03-20T15:30:00Z",
    )

  let sample_protocol =
    DeFiProtocol(
      id: "aave_v3",
      name: "Aave V3",
      network: types.Ethereum,
      tvl_usd: 5_000_000_000.0,
      apy: 4.5,
      risk_level: types.Low,
      supported_tokens: [
        "0xdac17f958d2ee523a2206206994597c13d831ec7",
        "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
      ],
      status: types.ProtocolActive,
    )

  let sample_position =
    Position(
      id: "pos1",
      protocol_id: "aave_v3",
      wallet_address: "0x1234...5678",
      position_type: types.Lending,
      token_address: "0xdac17f958d2ee523a2206206994597c13d831ec7",
      amount: 500.0,
      value_usd: 500.0,
      apy: 4.5,
      opened_at: "2024-03-20T12:00:00Z",
      last_updated: "2024-03-20T15:30:00Z",
    )

  #(
    Model(
      wallets: dict.from_list([#("wallet1", sample_wallet)]),
      protocols: dict.from_list([#("aave_v3", sample_protocol)]),
      positions: dict.from_list([#("pos1", sample_position)]),
      transactions: dict.new(),
      alerts: dict.new(),
      selected_wallet: Some("wallet1"),
      selected_protocol: Some("aave_v3"),
      nav_open: False,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    ConnectWallet(name, address, network) -> {
      let wallet =
        DeFiWallet(
          id: address,
          name: name,
          address: address,
          network: network,
          wallet_type: types.EOA,
          status: types.WalletActive,
          balance: 0.0,
          tokens: [],
          nfts: [],
          connected_at: "2024-03-20T10:00:00Z",
          last_activity: "2024-03-20T10:00:00Z",
        )
      #(
        Model(..model, wallets: dict.insert(model.wallets, address, wallet)),
        effect.none(),
      )
    }

    DisconnectWallet(address) -> {
      #(
        Model(..model, wallets: dict.delete(model.wallets, address)),
        effect.none(),
      )
    }

    LockWallet(address) -> {
      let wallets = case dict.get(model.wallets, address) {
        Ok(wallet) ->
          dict.insert(
            model.wallets,
            address,
            DeFiWallet(..wallet, status: types.WalletLocked),
          )
        Error(_) -> model.wallets
      }
      #(Model(..model, wallets: wallets), effect.none())
    }

    UnlockWallet(address) -> {
      let wallets = case dict.get(model.wallets, address) {
        Ok(wallet) ->
          dict.insert(
            model.wallets,
            address,
            DeFiWallet(..wallet, status: types.WalletActive),
          )
        Error(_) -> model.wallets
      }
      #(Model(..model, wallets: wallets), effect.none())
    }

    ArchiveWallet(address) -> {
      let wallets = case dict.get(model.wallets, address) {
        Ok(wallet) ->
          dict.insert(
            model.wallets,
            address,
            DeFiWallet(..wallet, status: types.WalletArchived),
          )
        Error(_) -> model.wallets
      }
      #(Model(..model, wallets: wallets), effect.none())
    }

    UpdateWalletTokens(address, tokens) -> {
      let wallets = case dict.get(model.wallets, address) {
        Ok(wallet) ->
          dict.insert(
            model.wallets,
            address,
            DeFiWallet(..wallet, tokens: tokens),
          )
        Error(_) -> model.wallets
      }
      #(Model(..model, wallets: wallets), effect.none())
    }

    UpdateWalletNFTs(address, nfts) -> {
      let wallets = case dict.get(model.wallets, address) {
        Ok(wallet) ->
          dict.insert(model.wallets, address, DeFiWallet(..wallet, nfts: nfts))
        Error(_) -> model.wallets
      }
      #(Model(..model, wallets: wallets), effect.none())
    }

    SelectWallet(address) -> {
      #(Model(..model, selected_wallet: Some(address)), effect.none())
    }

    SelectProtocol(id) -> {
      #(Model(..model, selected_protocol: Some(id)), effect.none())
    }

    DepositToProtocol(protocol_id, wallet_address, token_address, amount) -> {
      let position_id =
        protocol_id <> "_" <> wallet_address <> "_" <> token_address
      let position =
        Position(
          id: position_id,
          protocol_id: protocol_id,
          wallet_address: wallet_address,
          position_type: types.Lending,
          token_address: token_address,
          amount: amount,
          value_usd: amount,
          // Simplified, should use token price
          apy: 4.5,
          // Simplified, should get from protocol
          opened_at: "2024-03-20T12:00:00Z",
          last_updated: "2024-03-20T12:00:00Z",
        )
      #(
        Model(
          ..model,
          positions: dict.insert(model.positions, position_id, position),
        ),
        effect.none(),
      )
    }

    WithdrawFromProtocol(protocol_id, wallet_address, token_address, amount) -> {
      let position_id =
        protocol_id <> "_" <> wallet_address <> "_" <> token_address
      #(
        Model(..model, positions: dict.delete(model.positions, position_id)),
        effect.none(),
      )
    }

    CreatePosition(
      protocol_id,
      wallet_address,
      token_address,
      position_type,
      amount,
    ) -> {
      let position_id =
        protocol_id <> "_" <> wallet_address <> "_" <> token_address
      let position =
        Position(
          id: position_id,
          protocol_id: protocol_id,
          wallet_address: wallet_address,
          position_type: position_type,
          token_address: token_address,
          amount: amount,
          value_usd: amount,
          // Simplified, should use token price
          apy: 4.5,
          // Simplified, should get from protocol
          opened_at: "2024-03-20T12:00:00Z",
          last_updated: "2024-03-20T12:00:00Z",
        )
      #(
        Model(
          ..model,
          positions: dict.insert(model.positions, position_id, position),
        ),
        effect.none(),
      )
    }

    ClosePosition(position_id) -> {
      #(
        Model(..model, positions: dict.delete(model.positions, position_id)),
        effect.none(),
      )
    }

    SetAlertThreshold(wallet_address, alert_type, threshold) -> {
      let alert_id = wallet_address <> "_" <> alert_type_to_string(alert_type)
      let alert =
        DeFiAlert(
          id: alert_id,
          wallet_address: wallet_address,
          alert_type: alert_type,
          threshold: threshold,
          current_value: 0.0,
          triggered_at: "",
        )
      #(
        Model(..model, alerts: dict.insert(model.alerts, alert_id, alert)),
        effect.none(),
      )
    }

    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.ToggleNav -> #(
          Model(..model, nav_open: !model.nav_open),
          effect.none(),
        )
      }
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
    ],
    [
      element.map(nav.view(), NavMsg),
      html.main([attribute.class("defi-app")], [
        view_header(),
        view_wallets(model),
        view_protocols(model),
        view_positions(model),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("DeFi Dashboard")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Manage your DeFi positions and track performance"),
    ]),
  ])
}

fn view_wallets(model: Model) -> Element(Msg) {
  html.section([attribute.class("wallets-section")], [
    html.h2([], [html.text("Connected Wallets")]),
    html.div(
      [attribute.class("wallets-grid")],
      dict.values(model.wallets)
        |> list.map(view_wallet),
    ),
  ])
}

fn view_wallet(wallet: DeFiWallet) -> Element(Msg) {
  html.div([attribute.class("wallet-card")], [
    html.div([attribute.class("wallet-header")], [
      html.div([attribute.class("wallet-name")], [html.text(wallet.name)]),
      html.div([attribute.class("wallet-address")], [html.text(wallet.address)]),
    ]),
    html.div([attribute.class("wallet-details")], [
      html.div([attribute.class("wallet-balance")], [
        html.span([], [html.text("Balance")]),
        html.strong([], [html.text(float.to_string(wallet.balance) <> " ETH")]),
      ]),
      html.div([attribute.class("wallet-network")], [
        html.span([], [html.text("Network")]),
        html.strong([], [html.text(network_to_string(wallet.network))]),
      ]),
    ]),
    html.div([attribute.class("wallet-tokens")], [
      html.h3([], [html.text("Tokens")]),
      html.div(
        [attribute.class("token-list")],
        list.map(wallet.tokens, view_token),
      ),
    ]),
  ])
}

fn view_token(token: Token) -> Element(Msg) {
  html.div([attribute.class("token-item")], [
    html.div([attribute.class("token-info")], [
      html.span([attribute.class("token-symbol")], [html.text(token.symbol)]),
      html.span([attribute.class("token-balance")], [
        html.text(float.to_string(token.balance)),
      ]),
    ]),
    html.div([attribute.class("token-value")], [
      html.text("$" <> float.to_string(token.balance *. token.price_usd)),
    ]),
  ])
}

fn view_protocols(model: Model) -> Element(Msg) {
  html.section([attribute.class("protocols-section")], [
    html.h2([], [html.text("DeFi Protocols")]),
    html.div(
      [attribute.class("protocols-grid")],
      dict.values(model.protocols)
        |> list.map(view_protocol),
    ),
  ])
}

fn view_protocol(protocol: DeFiProtocol) -> Element(Msg) {
  html.div([attribute.class("protocol-card")], [
    html.div([attribute.class("protocol-header")], [
      html.div([attribute.class("protocol-name")], [html.text(protocol.name)]),
      html.div(
        [
          attribute.class(
            "protocol-status " <> protocol_status_class(protocol.status),
          ),
        ],
        [html.text(protocol_status_text(protocol.status))],
      ),
    ]),
    html.div([attribute.class("protocol-details")], [
      html.div([attribute.class("protocol-tvl")], [
        html.span([], [html.text("TVL")]),
        html.strong([], [
          html.text("$" <> format_large_number(protocol.tvl_usd)),
        ]),
      ]),
      html.div([attribute.class("protocol-apy")], [
        html.span([], [html.text("APY")]),
        html.strong([], [html.text(float.to_string(protocol.apy) <> "%")]),
      ]),
    ]),
    html.div([attribute.class("protocol-risk")], [
      html.span([], [html.text("Risk Level")]),
      html.div(
        [
          attribute.class(
            "risk-badge " <> risk_level_class(protocol.risk_level),
          ),
        ],
        [html.text(risk_level_text(protocol.risk_level))],
      ),
    ]),
  ])
}

fn view_positions(model: Model) -> Element(Msg) {
  html.section([attribute.class("positions-section")], [
    html.h2([], [html.text("Your Positions")]),
    html.div(
      [attribute.class("positions-grid")],
      dict.values(model.positions)
        |> list.map(view_position),
    ),
  ])
}

fn view_position(position: Position) -> Element(Msg) {
  html.div([attribute.class("position-card")], [
    html.div([attribute.class("position-header")], [
      html.div([attribute.class("position-type")], [
        html.text(position_type_text(position.position_type)),
      ]),
      html.div([attribute.class("position-amount")], [
        html.text("$" <> float.to_string(position.value_usd)),
      ]),
    ]),
    html.div([attribute.class("position-details")], [
      html.div([attribute.class("position-apy")], [
        html.span([], [html.text("APY")]),
        html.strong([], [html.text(float.to_string(position.apy) <> "%")]),
      ]),
      html.div([attribute.class("position-date")], [
        html.text("Opened: " <> position.opened_at),
      ]),
    ]),
    html.button(
      [
        attribute.class("close-position-btn"),
        event.on_click(ClosePosition(position.id)),
      ],
      [html.text("Close Position")],
    ),
  ])
}

fn network_to_string(network: Network) -> String {
  case network {
    types.Ethereum -> "Ethereum"
    types.Polygon -> "Polygon"
    types.Arbitrum -> "Arbitrum"
    types.Optimism -> "Optimism"
    types.BinanceSmartChain -> "BSC"
  }
}

fn protocol_status_class(status: ProtocolStatus) -> String {
  case status {
    types.ProtocolActive -> "status-active"
    types.ProtocolPaused -> "status-paused"
    types.ProtocolDeprecated -> "status-deprecated"
  }
}

fn protocol_status_text(status: ProtocolStatus) -> String {
  case status {
    types.ProtocolActive -> "Active"
    types.ProtocolPaused -> "Paused"
    types.ProtocolDeprecated -> "Deprecated"
  }
}

fn risk_level_class(level: RiskLevel) -> String {
  case level {
    types.Low -> "risk-low"
    types.Medium -> "risk-medium"
    types.High -> "risk-high"
  }
}

fn risk_level_text(level: RiskLevel) -> String {
  case level {
    types.Low -> "Low Risk"
    types.Medium -> "Medium Risk"
    types.High -> "High Risk"
  }
}

fn position_type_text(type_: PositionType) -> String {
  case type_ {
    types.Lending -> "Lending"
    types.Borrowing -> "Borrowing"
    types.LiquidityProviding -> "Liquidity"
    types.Staking -> "Staking"
    types.Farming -> "Yield Farming"
  }
}

fn alert_type_to_string(type_: AlertType) -> String {
  case type_ {
    types.LowBalance -> "low_balance"
    types.HighGas -> "high_gas"
    types.PriceMovement -> "price_movement"
    types.LiquidationRisk -> "liquidation_risk"
    types.PositionHealth -> "position_health"
  }
}

fn format_large_number(num: Float) -> String {
  case num {
    n if n >= 1_000_000_000.0 -> float.to_string(n /. 1_000_000_000.0) <> "B"
    n if n >= 1_000_000.0 -> float.to_string(n /. 1_000_000.0) <> "M"
    n if n >= 1000.0 -> float.to_string(n /. 1000.0) <> "K"
    n -> float.to_string(n)
  }
}
