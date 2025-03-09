import defi/divvy_integration
import defi/types.{
  type DeFiProtocol, type Position, type Token, DeFiProtocol, Position,
}
import divvyqueue/types.{
  type VerificationStatus, VerificationUnverified, VerificationVerified,
}
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// Test helper to create a sample protocol
fn sample_protocol() -> DeFiProtocol {
  DeFiProtocol(
    id: "aave_v3",
    name: "Aave V3",
    network: types.Ethereum,
    tvl_usd: 5_000_000_000.0,
    apy: 4.5,
    risk_level: types.Low,
    supported_tokens: [
      "0xdac17f958d2ee523a2206206994597c13d831ec7",
      // USDT
      "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
      // WBTC
    ],
    status: types.ProtocolActive,
  )
}

// Test helper to create a sample token
fn sample_token() -> Token {
  #(
    "0xdac17f958d2ee523a2206206994597c13d831ec7",
    // address
    "USDT",
    // symbol
    "Tether USD",
    // name
    6,
    // decimals
    1000.0,
    // balance
    1.0,
    // price_usd
    1,
    // chain_id
  )
}

pub fn create_defi_position_test() {
  let protocol = sample_protocol()
  let token = sample_token()
  let wallet = "0x1234...5678"
  let amount = 1000.0

  let result =
    divvy_integration.create_defi_position(
      protocol,
      wallet,
      types.Lending,
      amount,
      token,
    )

  should.be_ok(result)

  let position = result.unwrap()
  position.protocol_id
  |> should.equal(protocol.id)

  position.wallet_address
  |> should.equal(wallet)

  position.amount
  |> should.equal(amount)

  position.value_usd
  |> should.equal(amount *. token.price_usd)
}

pub fn verify_position_test() {
  let protocol = sample_protocol()
  let token = sample_token()
  let wallet = "0x1234...5678"
  let position =
    Position(
      id: protocol.id <> "_" <> wallet <> "_" <> token.address,
      protocol_id: protocol.id,
      wallet_address: wallet,
      position_type: types.Lending,
      token_address: token.address,
      amount: 1000.0,
      value_usd: 1000.0,
      apy: 4.5,
      opened_at: "2024-03-20T12:00:00Z",
      last_updated: "2024-03-20T12:00:00Z",
    )

  let result = divvy_integration.verify_position(position)
  should.be_ok(result)

  let status = result.unwrap()
  status
  |> should.equal(VerificationVerified)
}

pub fn track_position_test() {
  let protocol = sample_protocol()
  let token = sample_token()
  let wallet = "0x1234...5678"
  let position =
    Position(
      id: protocol.id <> "_" <> wallet <> "_" <> token.address,
      protocol_id: protocol.id,
      wallet_address: wallet,
      position_type: types.Lending,
      token_address: token.address,
      amount: 1000.0,
      value_usd: 1000.0,
      apy: 4.5,
      opened_at: "2024-03-20T12:00:00Z",
      last_updated: "2024-03-20T12:00:00Z",
    )

  let result = divvy_integration.track_position(position)
  should.be_ok(result)

  let tracked = result.unwrap()
  tracked.id
  |> should.equal(position.id)
}

pub fn close_position_test() {
  let protocol = sample_protocol()
  let token = sample_token()
  let wallet = "0x1234...5678"
  let position =
    Position(
      id: protocol.id <> "_" <> wallet <> "_" <> token.address,
      protocol_id: protocol.id,
      wallet_address: wallet,
      position_type: types.Lending,
      token_address: token.address,
      amount: 1000.0,
      value_usd: 1000.0,
      apy: 4.5,
      opened_at: "2024-03-20T12:00:00Z",
      last_updated: "2024-03-20T12:00:00Z",
    )

  let result = divvy_integration.close_position(position)
  // Currently expecting error as not implemented
  should.be_error(result)
}
