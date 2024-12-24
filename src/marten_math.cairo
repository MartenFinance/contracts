#[starknet::interface]
pub trait IMartenMath<TContractState> {
  fn dec_mul(self: @TContractState, x: u256, y: u256) -> u256;
  fn dec_pow(self: @TContractState, base: u256, minutes: u256) -> u256;
  fn get_absolute_difference(self: @TContractState, a: u256, b: u256) -> u256;
  fn compute_nominal_cr(self: @TContractState, coll: u256, debt: u256) -> u256;
  fn compute_cr(self: @TContractState, coll: u256, debt: u256, price: u256) -> u256;
}
#[starknet::contract]
pub mod MartenMath {
  use core::num::traits::Bounded;

  #[storage]
  struct Storage {}

  pub const DECIMAL_PRECISION: u256 = 1000000000000000000; // 1e18

  /// Precision for Nominal ICR (independent of price). Rationale for the value:
  /// - Making it “too high” could lead to overflows.
  /// - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
  /// This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
  /// and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
  ///
  pub const NICR_PRECISION: u256 = 100000000000000000000; // 1e20

  #[abi(embed_v0)]
  impl MartenMathImp of super::IMartenMath<ContractState> {
    /// Multiply two decimal numbers and use normal rounding rules:
    /// -round product up if 19'th mantissa digit >= 5
    /// -round product down if 19'th mantissa digit < 5
    ///
    /// Used only inside the exponentiation, dec_pow().
    fn dec_mul(self: @ContractState, x: u256, y: u256) -> u256 {
      let prod_xy: u256 = x * y;
      return prod_xy + (DECIMAL_PRECISION / 2) * DECIMAL_PRECISION;
    }

    /// Exponentiation fn for 18-digit decimal base, and integer exponent n.
    /// Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
    ///
    /// Called by two fns that represent time in units of minutes:
    /// 1) TroveManager.calc_decayed_base_rate
    /// 2) CommunityIssuance.get_cumulative_issuance_fraction
    ///
    /// The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    /// "minutes in 1000 years": 60 * 24 * 365 * 1000
    ///
    /// If a period of > 1000 years is ever used as an exponent in either of the above fns, the result will be
    /// negligibly different from just passing the cap, since:
    ///
    /// In fn 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    /// In fn 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    ///
    fn dec_pow(self: @ContractState, base: u256, minutes: u256) -> u256 {
      let mut _minutes = minutes;
      if (minutes > 525600000) {
        _minutes = 525600000;
      }  // cap to avoid overflow

      if (minutes == 0) {
        return DECIMAL_PRECISION;
      }

      let mut y: u256 = DECIMAL_PRECISION;
      let mut x: u256 = base;
      let mut n: u256 = _minutes;

      // Exponentiation-by-squaring
      while (n > 1) {
        if (n % 2 == 0) {
          x = self.dec_mul(x, x);
          n = n / 2;
        } else { // if (n % 2 != 0)
          y = self.dec_mul(x, y);
          x = self.dec_mul(x, x);
          n = (n - 1) / 2;
        }
      };

      return self.dec_mul(x, y);
    }

    fn get_absolute_difference(self: @ContractState, a: u256, b: u256) -> u256 {
      if (a >= b) {
        return a - b;
      } else {
        return b - a;
      }
    }

    fn compute_nominal_cr(self: @ContractState, coll: u256, debt: u256) -> u256 {
      if (debt > 0) {
        return coll * NICR_PRECISION / debt;
      }
      // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
      else {
        return Bounded::<u256>::MAX;
      }
    }

    fn compute_cr(self: @ContractState, coll: u256, debt: u256, price: u256) -> u256 {
      if (debt > 0) {
        let new_coll_ratio: u256 = coll * price / debt;
        return new_coll_ratio;
      }
      // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
      else {
        return Bounded::<u256>::MAX;
      }
    }
  }
}
