use starknet::ContractAddress;

#[starknet::interface]
pub trait IMartenStaking<TContractState> {
  fn set_addresses (
    ref self: TContractState,
    marten_token_address: ContractAddress,
    usdm_token_address: ContractAddress,
    vault_manager_address: ContractAddress,
    borrower_pperations_address: ContractAddress,
    active_pool_address: ContractAddress
  )

  fn stake(ref self: TContractState, amount: u256);
  fn unstake(ref self: TContractState, amount: u256);
  fn increaseF_ETH(ref self: TContractState, eth_fee: u256);
  fn increaseF_USDM(ref self: TContractState, marten_fee: u256);
  fn getPendingETHGain(self: @TContractState, user: ContractAddress) -> u256;
  fn getPendingUSDMGain(self: @TContractState, user: ContractAddress) -> u256;

  // #[derive(starknet::Event, Drop)]
  // pub struct MARTENTokenAddressSet {
  //   pub marten_token_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct USDMTokenAddressSet {
  //   pub usdm_token_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct VaultManagerAddressSet {
  //   pub vault_manager_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct BorrowerOperationsAddressSet {
  //   pub borrower_perations_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct ActivePoolAddressSet {
  //   pub active_pool_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct StakeChanged {
  //   pub staker: ContractAddress,
  //   pub new_stake: u256
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct StakingGainsWithdrawn {
  //   pub staker: ContractAddress,
  //   pub usdm_gain: u256,
  //   pub eth_gain: u256,
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct F_ETHUpdated {
  //   pub f_eth: u256
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct F_USDMUpdated {
  //   pub f_usdm: u256
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct TotalMARTENStakedUpdated {
  //   pub total_marten_staked: u256
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct EtherSent {
  //   pub account: ContractAddress,
  //   pub amount: u256
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct StakerSnapshotsUpdated {
  //   pub staker: ContractAddress,
  //   pub f_eth: u256
  //   pub f_usdm: u256
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   MARTENTokenAddressSet: MARTENTokenAddressSet,
  //   USDMTokenAddressSet: USDMTokenAddressSet,
  //   VaultManagerAddressSet: VaultManagerAddressSet,
  //   BorrowerOperationsAddressSet: BorrowerOperationsAddressSet,
  //   ActivePoolAddressSet: ActivePoolAddressSet,
  //   StakeChanged: StakeChanged,
  //   StakingGainsWithdrawn: StakingGainsWithdrawn,
  //   F_ETHUpdated: F_ETHUpdated,
  //   F_USDMUpdated: F_USDMUpdated,
  //   TotalMARTENStakedUpdated: TotalMARTENStakedUpdated,
  //   EtherSent: EtherSent,
  //   StakerSnapshotsUpdated: StakerSnapshotsUpdated,
  // }
}
