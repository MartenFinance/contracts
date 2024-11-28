use marten::interfaces::price_feed::{IPriceFeedTrait}

[#starknet::interface]
pub trait IMartenBase {
  fn price_feed() -> IPriceFeedTrait
}
