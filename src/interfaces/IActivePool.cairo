use starknet::{ContractAddress}
use marten::interface::IPool::IPool

#[starknet::interface]
#[abi(embed_v0)]
impl IActivePool of IPool<ContractState>{
  #[derive(starknet::Event, Drop)]
  pub struct BorrowerOperationsAddressChanged {
    pub newBorrowerOperationsAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub newVaultManagerAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolUSDMDebtUpdated {
    pub USDMDebt: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolETHBalanceUpdated {
    pub amount: u256
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    ActivePoolUSDMDebtUpdated: ActivePoolUSDMDebtUpdated,
    ActivePoolETHBalanceUpdated: ActivePoolETHBalanceUpdated,
  }

  fn send_eth(account: ContractAddress, amount: u256) external;
}
