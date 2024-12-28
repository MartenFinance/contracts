use starknet::ContractAddress;

#[starknet::interface]
pub trait IActivePool<TContractState> {
  fn set_addresses(
    ref self: TContractState,
    borrower_operations_address: ContractAddress,
    vault_manager_address: ContractAddress,
    stability_pool_address: ContractAddress,
    default_pool_address: ContractAddress,
    eth_token_address: ContractAddress,
  );
  fn get_eth(self: @TContractState) -> u256;
  fn get_usdm_debt(self: @TContractState) -> u256;
  fn deposit_eth(ref self: TContractState, amount: u256);
  fn send_eth(ref self: TContractState, recipient: ContractAddress, amount: u256);
  fn increase_usdm_debt(ref self: TContractState, amount: u256);
  fn decrease_usdm_debt(ref self: TContractState, amount: u256);
}
