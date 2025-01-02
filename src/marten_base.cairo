#[starknet::contract]
pub mod MartenBase {
  use starknet::ContractAddress;
  use OwnableComponent::InternalTrait;
  use core::num::traits::Zero;
  use openzeppelin::access::ownable::OwnableComponent;
  use marten::interfaces::marten_base::IMartenBase;
  use marten::interfaces::active_pool::{IActivePoolDispatcher, IActivePoolDispatcherTrait};
  use marten::interfaces::default_pool::{IDefaultPoolDispatcher, IDefaultPoolDispatcherTrait};
  use marten::marten_math::{IMartenMathDispatcher, IMartenMathDispatcherTrait};

  component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

  #[abi(embed_v0)]
  impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
  impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

  #[storage]
  struct Storage {
    #[substorage(v0)]
    ownable: OwnableComponent::Storage,
    pub active_pool_address: ContractAddress,
    pub default_pool_address: ContractAddress,
    pub price_feed_address: ContractAddress,
    pub marten_math_address: ContractAddress
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    #[flat]
    OwnableEvent: OwnableComponent::Event
  }

  pub const DECIMAL_PRECISION: u256 = 1000000000000000000; // 1e18
  pub const _100PCT: u256 = 1000000000000000000; // 1e18 == 100%

  // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
  pub const CCR: u256 = 1500000000000000000; // 150%

  // Amount of LUSD to be locked in gas pool on opening troves
  pub const USDM_GAS_COMPENSATION: u256 = 200000000000000000000; // 200e18;

  pub const PERCENT_DIVISOR: u256 = 200; // dividing by 200 yields 0.5%

  #[constructor]
  fn constructor(ref self: ContractState, owner: ContractAddress) {
    assert(Zero::is_non_zero(@owner), 'Owner cannot be zero addres');
    self.ownable.initializer(owner);
  }

  #[abi(embed_v0)]
  impl MartenBaseImpl of IMartenBase<ContractState> {
    fn set_addresses(
      ref self: ContractState,
      active_pool_address: ContractAddress,
      default_pool_address: ContractAddress,
      price_feed_address: ContractAddress,
      marten_math_address: ContractAddress,
    ) {
      self.ownable.assert_only_owner();

      self.active_pool_address.write(active_pool_address);
      self.default_pool_address.write(default_pool_address);
      self.price_feed_address.write(price_feed_address);
      self.marten_math_address.write(marten_math_address);

      self.ownable.renounce_ownership();
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

    fn get_entire_system_coll(self: @ContractState) -> u256 {
      let active_pool_contract: IActivePoolDispatcher = IActivePoolDispatcher { contract_address: self.active_pool_address.read() };
      let default_pool_contract: IDefaultPoolDispatcher = IDefaultPoolDispatcher { contract_address: self.default_pool_address.read() };

      let active_coll: u256 = active_pool_contract.get_eth();
      let liquidated_coll: u256 = default_pool_contract.get_eth();
      return active_coll + liquidated_coll;
    }

    fn get_entire_system_debt(self: @ContractState) -> u256 {
      let active_pool_contract: IActivePoolDispatcher = IActivePoolDispatcher { contract_address: self.active_pool_address.read() };
      let default_pool_contract: IDefaultPoolDispatcher = IDefaultPoolDispatcher { contract_address: self.default_pool_address.read() };

      let active_debt: u256 = active_pool_contract.get_usdm_debt();
      let closed_debt: u256 = default_pool_contract.get_usdm_debt();
      return active_debt + closed_debt;
    }

    fn get_tcr(self: @ContractState, price: u256) -> u256 {
      let marten_math_contract: IMartenMathDispatcher = IMartenMathDispatcher { contract_address: self.marten_math_address.read() };

      let entire_system_coll: u256 = self.get_entire_system_coll();
      let entire_system_debt: u256 = self.get_entire_system_debt();

      return marten_math_contract.compute_cr(entire_system_coll, entire_system_debt, price);
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
