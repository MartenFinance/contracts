use starknet::ContractAddress;
use marten::interfaces::usdm_token::{IUSDMTokenDispatcher};
use marten::interfaces::marten_token::{IMARTENTokenDispatcher};
use marten::interfaces::marten_staking::{IMARTENStakingDispatcher};
use marten::interfaces::price_feed::{IPriceFeedTrait};

#[derive(Drop, Serde, starknet::Store)]
pub struct DebtAndCollInfo {
  debt: u256,
  coll: u256,
  pending_usdm_debt_reward: u256,
  pending_eth_reward: u256
}

#[starknet::interface]
pub trait IVaultManager<TContractState> {
  // #[derive(starknet::Event, Drop)]
  // pub struct borrower_operations_address_changed {
  //   pub new_borrower_operations_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct price_feed_address_changed {
  //   pub new_price_feed_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct usdm_token_address_changed {
  //   pub new_usdm_token_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct active_pool_address_changed {
  //   pub active_pool_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct default_pool_address_changed {
  //   pub default_pool_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct stability_pool_address_changed {
  //   pub stability_pool_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct gas_pool_address_changed {
  //   pub gas_pool_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct coll_surplus_pool_address_changed {
  //   pub coll_surplus_pool_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct sorted_vaults_address_changed {
  //   pub sorted_vaults_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct marten_token_address_changed {
  //   pub marten_token_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct marten_staking_address_changed {
  //   pub marten_staking_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct liquidation {
  //   pub liquidated_debt: u256,
  //   pub liquidated_coll: u256,
  //   pub coll_gas_compensation: u256,
  //   pub usdm_gas_compensation: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct redemption {
  //   pub attempted_usdm_amount: u256,
  //   pub actual_usdm_amount: u256,
  //   pub eth_sent: u256,
  //   pub eth_fee: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct vault_updated {
  //   pub borrower: ContractAddress,
  //   pub debt: u256,
  //   pub coll: u256,
  //   pub stake: u256,
  //   pub operation: u8
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct vault_liquidated {
  //   pub borrower: ContractAddress,
  //   pub debt: u256,
  //   pub coll: u256,
  //   pub operation: u8
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct base_rate_updated {
  //   pub base_rate: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct last_fee_op_time_updated {
  //   pub last_fee_op_time: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct total_stakes_updated {
  //   pub new_total_stakes: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct system_snapshots_updated {
  //   pub total_stakes_snapshot: u256,
  //   pub total_collateral_snapshot: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct l_terms_updated {
  //   pub l_eth: u256,
  //   pub l_usdm_debt: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct vault_snapshots_updated {
  //   pub l_eth: u256,
  //   pub l_usdm_debt: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub struct vault_index_updated {
  //   pub borrower: ContractAddress,
  //   pub new_index: u256
  // };

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // pub enum Event {
  //   BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
  //   PriceFeedAddressChanged: PriceFeedAddressChanged,
  //   LUSDTokenAddressChanged: LUSDTokenAddressChanged,
  //   ActivePoolAddressChanged: ActivePoolAddressChanged,
  //   DefaultPoolAddressChanged: DefaultPoolAddressChanged,
  //   StabilityPoolAddressChanged: StabilityPoolAddressChanged,
  //   GasPoolAddressChanged: GasPoolAddressChanged,
  //   CollSurplusPoolAddressChanged: CollSurplusPoolAddressChanged,
  //   SortedTrovesAddressChanged: SortedTrovesAddressChanged,
  //   LQTYTokenAddressChanged: LQTYTokenAddressChanged,
  //   LQTYStakingAddressChanged: LQTYStakingAddressChanged,
  //   Liquidation: Liquidation,
  //   Redemption: Redemption,
  //   TroveUpdated: TroveUpdated,
  //   TroveLiquidated: TroveLiquidated,
  //   BaseRateUpdated: BaseRateUpdated,
  //   LastFeeOpTimeUpdated: LastFeeOpTimeUpdated,
  //   TotalStakesUpdated: TotalStakesUpdated,
  //   SystemSnapshotsUpdated: SystemSnapshotsUpdated,
  //   LTermsUpdated: LTermsUpdated,
  //   TroveSnapshotsUpdated: TroveSnapshotsUpdated,
  //   TroveIndexUpdated: TroveIndexUpdated
  // }

  fn set_addresses(
    ref self: TContractState,
    borrower_operations_address: ContractAddress,
    active_pool_address: ContractAddress,
    default_pool_address: ContractAddress,
    stability_pool_address: ContractAddress,
    gas_pool_address: ContractAddress,
    coll_surplus_pool_address: ContractAddress,
    price_feed_address: ContractAddress,
    usdm_token_address: ContractAddress,
    sorted_vaults_address: ContractAddress,
    marten_token_address: ContractAddress,
    marten_staking_address: ContractAddress
  );

  fn price_feed(self: @TContractState) -> IPriceFeedTrait;
  fn stability_pool(self: @TContractState) -> IStabilityPoolDispatcher;
  fn usdm_token(self: @TContractState) -> IUSDMTokenDispatcher;
  fn marten_token(self: @TContractState) -> IMARTENTokenDispatcher;
  fn marten_staking(self: @TContractState) -> IMARTENStakingDispatcher;

  fn get_vault_owners_count(self: @TContractState) -> u256;

  fn get_vault_from_vault_owners_array(self: @TContractState, index: u256) -> u256;

  fn get_nominal_icr(self: @TContractState, borrower: ContractAddress) -> u256;
  fn get_current_icr(self: @TContractState, borrower: ContractAddress, price: u256) -> u256;

  fn liquidate(ref self: TContractState, borrower: ContractAddress);

  fn liquidate_vaults(ref self: TContractState, n: u256);

  fn batch_liquidate_vaults(ref self: TContractState, vault_array: Array<ContractAddress>);

  fn redeem_collateral(
    ref self: TContractState,
    usdm_amount: u256,
    first_redemption_hint: ContractAddress,
    upper_partial_redemption_hint: ContractAddress,
    lower_partial_redemption_hint: ContractAddress,
    partial_redemption_hint_nicr: u256,
    max_iterations: u256,
    max_fee: u256
  );

  fn update_stake_and_total_stakes(ref self: TContractState, borrower: ContractAddress) -> u256;

  fn update_vault_reward_snapshots(ref self: TContractState, borrower: ContractAddress);

  fn add_vault_owner_to_array(ref self: TContractState, borrower: ContractAddress) -> u256;

  fn apply_pending_rewards(ref self: TContractState, borrower: ContractAddress);

  fn get_pending_eth_reward(self: @TContractState, borrower: ContractAddress) -> u256;

  fn get_pending_usdm_debt_reward(self: @TContractState, borrower: ContractAddress) -> u256;

  fn has_pending_rewards(self: @TContractState, borrower: ContractAddress) -> bool;

  fn get_entire_debt_and_coll(self: @TContractState, borrower: ContractAddress) -> DebtAndCollInfo;

  fn close_vault(ref self: TContractState, borrower: ContractAddress);

  fn remove_stake(ref self: TContractState, borrower: ContractAddress);

  fn get_redemption_rate(self: @TContractState) -> u256;
  fn get_redemption_rate_with_decay(self: @TContractState) -> u256;

  fn get_redemption_fee_with_decay(self: @TContractState, eth_drawn: u256) -> u256;

  fn get_borrowing_rate(self: @TContractState) -> u256;
  fn get_borrowing_rate_with_decay(self: @TContractState) -> u256;

  fn get_borrowing_fee(self: @TContractState, usdm_debt: u256) -> u256;
  fn get_borrowing_fee_with_decay(self: @TContractState, usdm_debt: u256) -> u256;

  fn decay_base_rate_from_borrowing(ref self: TContractState);

  fn get_vault_status(self: @TContractState, borrower: ContractAddress) -> u256;

  fn get_vault_stake(self: @TContractState, borrower: ContractAddress) -> u256;

  fn get_vault_debt(self: @TContractState, borrower: ContractAddress) -> u256;

  fn get_vault_coll(self: @TContractState, borrower: ContractAddress) -> u256;

  fn set_vault_status(ref self: TContractState, borrower: ContractAddress, num: u256);

  fn increase_vault_coll(ref self: TContractState, borrower: ContractAddress, coll_increase: u256) -> u256;

  fn decrease_vault_coll(ref self: TContractState, borrower: ContractAddress, coll_decrease: u256) -> u256;

  fn increase_vault_debt(ref self: TContractState, borrower: ContractAddress, debt_increase: u256) -> u256;

  fn decrease_vault_debt(ref self: TContractState, borrower: ContractAddress, coll_decrease: u256) -> u256;

  fn get_tcr(self: @TContractState, price: u256) -> u256;

  fn check_recovery_mode(self: @TContractState, price: u256) -> bool;
}
