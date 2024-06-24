use starknet::{ContractAddress};
use marten::interface::IPool::IPool;

#[starknet::interface]
#[abi(embed_v0)]
impl IDefaultPool of <ContractState> {
  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub new_vault_manager_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolUSDMDebtUpdated {
    pub usdm_debt: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolETHBalanceUpdated {
    pub amount: u256
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    DefaultPoolUSDMDebtUpdated: DefaultPoolUSDMDebtUpdated,
    DefaultPoolETHBalanceUpdated: DefaultPoolETHBalanceUpdated
  }

  fn send_eth_to_active_pool(amount: u256);
}
