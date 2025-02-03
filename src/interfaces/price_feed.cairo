#[starknet::interface]
pub trait IPriceFeed<TContractState> {
  fn fetch_price(self: @TContractState) -> u256;
}
