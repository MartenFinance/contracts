#[starknet::interface]
pub trait IDefaultPool<TContractState> {
  // #[derive(starknet::Event, Drop)]
  // pub struct VaultManagerAddressChanged {
  //   pub new_vault_manager_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct DefaultPoolUSDMDebtUpdated {
  //   pub usdm_debt: u256
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct DefaultPoolETHBalanceUpdated {
  //   pub amount: u256
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   VaultManagerAddressChanged: VaultManagerAddressChanged,
  //   DefaultPoolUSDMDebtUpdated: DefaultPoolUSDMDebtUpdated,
  //   DefaultPoolETHBalanceUpdated: DefaultPoolETHBalanceUpdated
  // }

  fn get_eth(self: @TContractState) -> u256;
  fn get_usdm_debt(self: @TContractState) -> u256;
  fn send_eth_to_active_pool(self: @TContractState, amount: u256);
}
