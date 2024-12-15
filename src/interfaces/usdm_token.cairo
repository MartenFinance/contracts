use starknet::ContractAddress;

#[starknet::interface]
pub trait IUSDMToken<TContractState> {
  fn mint(ref self: TContractState, account: ContractAddress, amount: u256);
  fn burn(ref self: TContractState, account: ContractAddress, amount: u256);
  fn send_to_pool(ref self: TContractState, ender: ContractAddress, pool_address: ContractAddress, amount: u256);
  fn return_from_pool(ref self: TContractState, pool_address: ContractAddress, user: ContractAddress, amount: u256);
  // #[derive(starknet::Event, Drop)]
  // pub struct VaultManagerAddressChanged {
  //   pub vault_manager_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct StabilityPoolAddressChanged {
  //   pub new_stability_pool_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct BorrowerOperationsAddressChanged {
  //   pub new_borrower_operations_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct USDMTokenBalanceUpdated {
  //   pub user: ContractAddress,
  //   pub amount: u256
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   VaultManagerAddressChanged: VaultManagerAddressChanged,
  //   StabilityPoolAddressChanged: StabilityPoolAddressChanged,
  //   BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
  //   USDMTokenBalanceUpdated: USDMTokenBalanceUpdated,
  // }
}
