use starknet::ContractAddress;

#[starknet::interface]
pub trait ICollSurplusPool<TContractState> {
  fn set_addresses (
    ref self: TContractState,
    borrower_operations_address: ContractAddress,
    vault_manager_address: ContractAddress,
    active_pool_address: ContractAddress,
    eth_token_address: ContractAddress
  );

  fn get_eth(self: @TContractState) -> u256;

  fn get_collateral(self: @TContractState, account: ContractAddress) -> u256;

  fn account_surplus(ref self: TContractState, account: ContractAddress, amount: u256);

  fn claim_coll(ref self: TContractState, account: ContractAddress);
}
