use starknet::ContractAddress;

#[starknet::interface]
pub trait IStabilityPool {
  #[derive(starknet::Event, Drop)]
  pub struct StabilityPoolETHBalanceUpdated {
    pub new_balance: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct StabilityPoolLUSDBalanceUpdated {
    pub new_balance: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct BorrowerOperationsAddressChanged {
    pub new_borrower_operations_address: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct TroveManagerAddressChanged {
    pub new_trove_manager_address: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolAddressChanged {
    pub new_active_pool_address: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolAddressChanged {
    pub new_default_pool_address: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct USDMokenAddressChanged {
    pub new_usdm_tokenaddress: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct SortedTrovesAddressChanged {
    pub new_sorted_troves_address: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct PriceFeedAddressChanged {
    pub new_price_feed_address: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct CommunityIssuanceAddressChanged {
    pub new_community_issuance_address: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct P_Updated {
    pub p: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct S_Updated {
    pub s: u256,
    pub epoch: u128,
    pub scale: u128
  };

  #[derive(starknet::Event, Drop)]
  pub struct G_Updated {
    pub g: u256,
    pub epoch: u128,
    pub scale: u128
  };

  #[derive(starknet::Event, Drop)]
  pub struct EpochUpdated {
    pub current_epoch: u128
  };

  #[derive(starknet::Event, Drop)]
  pub struct ScaleUpdated {
    pub current_scale: u128
  };

  #[derive(starknet::Event, Drop)]
  pub struct FrontEndRegistered {
    pub front_end: ContractAddress,
    pub kickback_rate: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct FrontEndTagSet {
    pub depositor: ContractAddress,
    pub front_end: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct DepositSnapshotUpdated {
    pub depositor: ContractAddress,
    pub p: u256,
    pub s: u256,
    pub g: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct FrontEndSnapshotUpdated {
    pub front_end: ContractAddress,
    pub p: u256,
    pub g: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct UserDepositChanged {
    pub depositor: ContractAddress,
    pub new_deposit: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct FrontEndStakeChanged {
    pub front_end: ContractAddress,
    pub new_front_end_stake: u256,
    pub depositor: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub struct ETHGainWithdrawn {
    pub depositor: ContractAddress,
    pub eth: u256,
    pub usdm_loss: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct MartenPaidToDepositor {
    pub depositor: ContractAddress,
    pub amount: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct MartenPaidToFrontEnd {
    pub front_end: ContractAddress,
    pub amount: u256
  };

  #[derive(starknet::Event, Drop)]
  pub struct EtherSent {
    pub to: ContractAddress,
    pub amount: u256
  };

  fn set_addresses(
    borrower_operations_address: ContractAddress,
    trove_manager_address: ContractAddress,
    active_pool_address: ContractAddress,
    lusd_token_address: ContractAddress,
    sorted_troves_address: ContractAddress,
    price_feed_address: ContractAddress,
    community_issuance_address: ContractAddress
  );

  fn provide_to_sp(amount: u256, front_end_tag: ContractAddress);

  fn withdraw_from_sp(amount: u256);

  fn withdraw_eth_gain_to_trove(upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn register_front_end(kickback_rate: ContractAddress);

  fn offset(debt: u256, coll: u256);

  fn get_eth() -> u256;

  fn get_total_lusd_deposits() -> u256;

  fn get_depositor_eth_gain(depositor: ContractAddress) -> u256;

  fn get_depositor_lqty_gain(depositor: ContractAddress) -> u256;

  fn get_front_end_lqty_gain(front_end: ContractAddress) -> u256;

  fn get_compounded_lusd_deposit(depositor: ContractAddress) -> u256;

  fn get_compounded_front_end_stake(front_end: ContractAddress) -> u256;
}
