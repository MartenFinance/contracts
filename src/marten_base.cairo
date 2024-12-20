#[starknet::contract]
pub mod MartenBase {
  use starknet::{ContractAddress};
  use marten::interfaces::marten_base::IMartenBase;
  use marten::interfaces::active_pool::{IActivePoolDispatcher, IActivePoolDispatcherTrait};
  use marten::interfaces::default_pool::{IDefaultPoolDispatcher, IDefaultPoolDispatcherTrait};
  use marten::marten_math::{IMartenMathDispatcher, IMartenMathDispatcherTrait};

  #[storage]
  struct Storage {
    pub active_pool_address: ContractAddress,
    pub default_pool_address: ContractAddress,
    pub price_feed_address: ContractAddress,
    pub marten_math_address: ContractAddress
  }

  const DECIMAL_PRECISION: u256 = 1000000000000000000; // 1e18
  pub const _100PCT: u256 = 1000000000000000000; // 1e18 == 100%

  // Minimum collateral ratio for individual troves
  pub const MCR: u256 = 1100000000000000000; // 110%

  // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
  pub const CCR: u256 = 1500000000000000000; // 150%

  // Amount of LUSD to be locked in gas pool on opening troves
  pub const USDM_GAS_COMPENSATION: u256 = 200000000000000000000; // 200e18;

  // Minimum amount of net LUSD debt a trove must have
  pub const MIN_NET_DEBT: u256 = 1800000000000000000000; // 1800e18;

  pub const PERCENT_DIVISOR: u256 = 200; // dividing by 200 yields 0.5%

  pub const BORROWING_FEE_FLOOR: u256 = DECIMAL_PRECISION / 1000 * 5; // 0.5%

  impl MartenBaseImpl of IMartenBase<ContractState> {
    fn set_addresses(
      ref self: ContractState,
      active_pool_address: ContractAddress,
      default_pool_address: ContractAddress,
      price_feed_address: ContractAddress,
      marten_math_address: ContractAddress,
    ) {
      self.active_pool_address.write(active_pool_address);
      self.default_pool_address.write(default_pool_address);
      self.price_feed_address.write(price_feed_address);
      self.marten_math_address.write(marten_math_address);
    }

    fn get_composite_debt(self: @ContractState, debt: u256) -> u256 {
       return debt + USDM_GAS_COMPENSATION;
    }

    fn get_net_debt(self: @ContractState, debt: u256) -> u256 {
      return debt - USDM_GAS_COMPENSATION;
    }

    fn get_coll_gas_compensation(self: @ContractState, entire_coll: u256) -> u256 {
      return entire_coll / PERCENT_DIVISOR;
    }

    fn get_entire_system_col(self: @ContractState) -> u256 {
      let active_pool: IActivePoolDispatcher = IActivePoolDispatcher { contract_address: self.active_pool_address.read() };
      let default_pool: IDefaultPoolDispatcher = IDefaultPoolDispatcher { contract_address: self.default_pool_address.read() };

      let active_coll: u256 = active_pool.get_eth();
      let liquidated_coll: u256 = default_pool.get_eth();
      return active_coll + liquidated_coll;
    }

    fn get_entire_system_debt(self: @ContractState) -> u256 {
      let active_pool: IActivePoolDispatcher = IActivePoolDispatcher { contract_address: self.active_pool_address.read() };
      let default_pool: IDefaultPoolDispatcher = IDefaultPoolDispatcher { contract_address: self.default_pool_address.read() };

      let active_debt: u256 = active_pool.get_usdm_debt();
      let closed_debt: u256 = default_pool.get_usdm_debt();
      return active_debt + closed_debt;
    }

    fn get_tcr(self: @ContractState, price: u256) -> u256 {
      let marten_math: IMartenMathDispatcher = IMartenMathDispatcher { contract_address: self.marten_math_address.read() };

      let entire_system_coll: u256 = self.get_entire_system_col();
      let entire_system_debt: u256 = self.get_entire_system_debt();

      return marten_math.compute_cr(entire_system_coll, entire_system_debt, price);
    }

    fn check_recovery_mode(self: @ContractState, price: u256) -> bool {
      let tcr: u256 = self.get_tcr(price);
      return tcr < CCR;
    }

    fn require_user_accepts_fee(self: @ContractState, fee: u256, amount: u256, max_fee_percentage: u256) -> bool {
      let fee_percentage: u256 = fee * DECIMAL_PRECISION / amount;
      return fee_percentage <= max_fee_percentage;
    }
  }
}
