use starknet::ContractAddress;

#[starknet::interface]
pub trait ICollSurplusPool<TContractState> {
  fn set_addresses (
    ref self: TContractState,
    borrower_operations_address: ContractAddress,
    vault_manager_address: ContractAddress,
    active_pool_address: ContractAddress
  );

  fn get_eth(self: @TContractState) -> u256;

  fn get_collateral(self: @TContractState, account: ContractAddress) -> u256;

  fn account_surplus(ref self: TContractState, account: ContractAddress, amount: u256);

  fn claim_coll(ref self: TContractState, account: ContractAddress);
  // #[derive(starknet::Event, Drop)]
  // pub struct BorrowerOperationsAddressChanged {
  //   pub new_borrower_operations_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct VaultManagerAddressChanged {
  //   pub new_vault_manager_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct ActivePoolAddressChanged {
  //   pub new_active_pool_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct CollBalanceUpdated {
  //   pub account: ContractAddress,
  //   pub new_balance: u256
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct EtherSent {
  //   pub to: ContractAddress,
  //   pub amount: u256
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
  //   VaultManagerAddressChanged: VaultManagerAddressChanged,
  //   ActivePoolAddressChanged: ActivePoolAddressChanged,
  //   CollBalanceUpdated: CollBalanceUpdated,
  //   EtherSent: EtherSent
  // }
}
