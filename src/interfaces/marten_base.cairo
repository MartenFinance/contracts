use starknet::ContractAddress;

#[starknet::interface]
pub trait IMartenBase<TContractState> {
  fn set_addresses(
    ref self: TContractState,
    active_pool_address: ContractAddress,
    default_pool_address: ContractAddress,
    price_feed_address: ContractAddress,
    marten_math_address: ContractAddress
  );
  fn get_composite_debt(self: @TContractState, debt: u256) -> u256;
  fn get_net_debt(self: @TContractState, debt: u256) -> u256;
  fn get_coll_gas_compensation(self: @TContractState, entire_coll: u256) -> u256;
  fn get_entire_system_coll(self: @TContractState) -> u256;
  fn get_entire_system_debt(self: @TContractState) -> u256;
  fn get_tcr(self: @TContractState, price: u256) -> u256;
  fn check_recovery_mode(self: @TContractState, price: u256) -> bool;
  fn require_user_accepts_fee(self: @TContractState, fee: u256, amount: u256, max_fee_percentage: u256) -> bool;
}
