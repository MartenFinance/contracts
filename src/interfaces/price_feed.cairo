#[starknet::interface]
pub trait IPriceFeed {
  // #[derive(starknet::Event, Drop)]
  // pub struct LastGoodPriceUpdated {
  //   pub last_good_price: u256
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   LastGoodPriceUpdated: LastGoodPriceUpdated,
  // }
  fn fetch_price() -> u256;
}
