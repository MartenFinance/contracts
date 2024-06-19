use starknet::{ContractAddress}

#[starknet::interface]
pub trait IBorrowerOperations {
  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub newVaultManagerAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolAddressChanged {
    pub activePoolAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolAddressChanged {
    pub defaultPoolAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct StabilityPoolAddressChanged {
    pub stabilityPoolAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct GasPoolAddressChanged {
    pub gasPoolAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct CollSurplusPoolAddressChanged {
    pub collSurplusPoolAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct PriceFeedAddressChanged {
    pub newPriceFeedAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct SortedVaultsAddressChanged {
    pub sortedVaultsAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMTokenAddressChanged {
    pub usdmTokenAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct MARTENStakingAddressChanged {
    pub martenStakingAddress: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultCreated {
    pub borrower: ContractAddress
    pub arrayIndex: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultUpdated {
    pub borrower: ContractAddress
    pub debt: u256
    pub coll: u256
    pub stake: u256
    pub operation: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMBorrowingFeePaid {
    pub borrower: ContractAddress
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
    vaultManagerAddress ContractAddress,
    activePoolAddress ContractAddress,
    defaultPoolAddress ContractAddress,
    address _stabilityPoolAddress,
    address _gasPoolAddress,
    address _collSurplusPoolAddress,
    address _priceFeedAddress,
    address _sortedTrovesAddress,
    address _lusdTokenAddress,
    address _lqtyStakingAddress
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
