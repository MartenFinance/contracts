use starknet::ContractAddress;

#[starknet::interface]
pub trait IDefaultPool<TContractState> {
  fn set_addresses(
    ref self: TContractState,
    vault_manager_address: ContractAddress,
    active_pool_address: ContractAddress,
    eth_token_address: ContractAddress
  );

  fn deposit_eth(ref self: TContractState, amount: u256);

  fn get_eth(self: @TContractState) -> u256;

  fn get_usdm_debt(self: @TContractState) -> u256;

  fn send_eth_to_active_pool(ref self: TContractState, amount: u256);

  fn increase_usdm_debt(ref self: TContractState, amount: u256);

  fn decrease_usdm_debt(ref self: TContractState, amount: u256);
}
