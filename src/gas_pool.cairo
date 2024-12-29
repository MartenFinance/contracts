#[starknet::contract]

///
/// The purpose of this contract is to hold USDM tokens for gas compensation:
/// When a borrower opens a trove, an additional 50 USDM debt is issued,
/// and 50 USDM is minted and sent to this contract.
/// When a borrower closes their active trove, this gas compensation is refunded:
/// 50 USDM is burned from the this contract's balance, and the corresponding
/// 50 USDM debt on the trove is cancelled.
/// See this issue for more context: https://github.com/liquity/dev/issues/186
///
pub mod GasPool {
  #[storage]
  struct Storage {  }
}
