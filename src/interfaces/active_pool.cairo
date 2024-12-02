use starknet::ContractAddress;

#[starknet::interface]
pub trait IActivePool<TContractState> {
  fn get_eth(self: @TContractState) -> u256;
  fn get_usdm_debt(self: @TContractState) -> u256;
  fn deposit_eth(ref self: TContractState, amount: u256);
  fn send_eth(ref self: TContractState, recipient: ContractAddress, amount: u256);
  fn increase_usdm_debt(ref self: TContractState, amount: u256);
  fn decrease_usdm_debt(ref self: TContractState, amount: u256);
}
