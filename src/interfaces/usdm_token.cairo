use starknet::ContractAddress;

#[starknet::interface]
pub trait IUSDMToken<TContractState> {
  fn set_addresses(
    ref self: TContractState,
    borrower_operations_address: ContractAddress,
    vault_manager_address: ContractAddress,
    stability_pool_address: ContractAddress,
  );
  fn mint(ref self: TContractState, account: ContractAddress, amount: u256);
  fn burn(ref self: TContractState, account: ContractAddress, amount: u256);
  fn send_to_pool(ref self: TContractState, sender: ContractAddress, pool_address: ContractAddress, amount: u256);
  fn return_from_pool(ref self: TContractState, pool_address: ContractAddress, recipient: ContractAddress, amount: u256);
}
