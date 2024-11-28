use starknet::ContractAddress;

#[starknet::interface]
pub trait IBorrowerOperations {
  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub new_vault_manager_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolAddressChanged {
    pub active_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolAddressChanged {
    pub default_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct StabilityPoolAddressChanged {
    pub stability_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct GasPoolAddressChanged {
    pub gas_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct CollSurplusPoolAddressChanged {
    pub coll_surplusP_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct PriceFeedAddressChanged {
    pub new_price_feed_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct SortedVaultsAddressChanged {
    pub sorted_vaults_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMTokenAddressChanged {
    pub usdm_token_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct MARTENStakingAddressChanged {
    pub marten_staking_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultCreated {
    pub borrower: ContractAddress,
    pub arrayIndex: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultUpdated {
    pub borrower: ContractAddress,
    pub debt: u256,
    pub coll: u256,
    pub stake: u256,
    pub operation: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMBorrowingFeePaid {
    pub borrower: ContractAddress,
    pub USDMFee: u256
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    ActivePoolAddressChanged: ActivePoolAddressChanged,
    ActivePoolAddressChanged: ActivePoolAddressChanged,
    DefaultPoolAddressChanged: DefaultPoolAddressChanged,
    StabilityPoolAddressChanged: StabilityPoolAddressChanged,
    GasPoolAddressChanged: GasPoolAddressChanged,
    CollSurplusPoolAddressChanged: CollSurplusPoolAddressChanged,
    PriceFeedAddressChanged: PriceFeedAddressChanged,
    SortedVaultsAddressChanged: SortedVaultsAddressChanged,
    USDMTokenAddressChanged: USDMTokenAddressChanged,
    MARTENStakingAddressChanged: MARTENStakingAddressChanged,
    VaultCreated: VaultCreated,
    VaultUpdated: VaultUpdated,
  }

  fn set_addresses(
    vault_manager_address: ContractAddress,
    active_pool_address: ContractAddress,
    default_pool_address: ContractAddress,
    stability_pool_address: ContractAddress,
    gas_pool_address: ContractAddress,
    coll_surplus_pool_address: ContractAddress,
    price_feed_address: ContractAddress,
    sorted_vaults_address: ContractAddress,
    lusd_token_address: ContractAddress,
    lqty_staking_address: ContractAddress,
  );

  fn open_vault(max_fee: uint, usdm_mount: uint, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn add_coll(upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn move_eth_gain_to_vault(user: ContractAddress, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn withdraw_coll(amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn withdraw_usdm(maxFee: u256, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn repay_usdm(amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn close_vault();

  fn adjust_vault(max_fee: u256, coll_withdrawal: u256, debt_change: u256, is_debt_increase: bool, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn claim_collateral();

  fn get_composite_debt(debt u256) -> u256;
}
