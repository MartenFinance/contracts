use starknet::{ContractAddress};

#[starknet::interface]
pub trait ICommunityIssuance {
  #[derive(starknet::Event, Drop)]
  pub struct MartenTokenAddressSet {
    pub marten_token_address_set: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct StabilityPoolAddressSet {
    pub stability_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct TotalMartenIssuedUpdated {
    pub total_marten_issued: u256
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    MartenTokenAddressSet: MartenTokenAddressSet,
    StabilityPoolAddressSet: StabilityPoolAddressSet,
    TotalMartenIssuedUpdated: TotalMartenIssuedUpdated
  }

  fn set_addresses(marten_token_address: ContractAddress, stability_pool_address: ContractAddress);

  fn issue_marten() -> u256;

  fn send_marten(account: ContractAddress, marten_amount: u256);
}
