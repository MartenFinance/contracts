#[starknet::interface]
pub trait IPriceFeed<TContractState> {
  // #[derive(starknet::Event, Drop)]
  // pub struct LastGoodPriceUpdated {
  //   pub last_good_price: u256
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   LastGoodPriceUpdated: LastGoodPriceUpdated,
  // }
  fn fetch_price(self: @TContractState) -> u256;
}
