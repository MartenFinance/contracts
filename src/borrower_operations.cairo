#[starknet::contract]
pub mod BorrowerOperations {
  use starknet::{ContractAddress, get_caller_address};
  use core::num::traits::Zero;
  use openzeppelin::access::ownable::OwnableComponent;
  use marten::interfaces::active_pool::IBorrowerOperations;
  use marten::interfaces::erc20::{IERC20Dispatcher};
  use marten::interface::active_pool::{IActivePoolDispatcher};
  use marten::interface::coll_surplus::{ICollSurplusPoolDispatcher};
  use marten::interface::usdm_token::{IUSDMTokenDispatcher};
  use marten::interface::vault_manager::{IVaultManagerDispatcher};
  use marten::interface::sorted_vaults::{ISortedVaultsDispatcher};

  component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

  #[abi(embed_v0)]
  impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
  impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

  #[storage]
  struct Storage {
    #[substorage(v0)]
    ownable: OwnableComponent::Storage,
    stability_pool_address: ContractAddress,
    gas_pool_address: ContractAddress,
    marten_staking_address: ContractAddress,
    vault_manager: IVaultManagerDispatcher,
    active_pool: IActivePoolDispatcher,
    coll_surplus_pool: ICollSurplusPoolDispatcher,
    marten_staking: IMartenStakingDispatcher,
    usdm_token: IUSDMTokenDispatcher,
    sorted_vaults: ISortedVaultsDispatcher // A doubly linked list of Vaults, sorted by their collateral ratios
  }

  pub const NAME = "BorrowerOperations";

  #[derive(Drop, Clone, Serde, starknet::Store)]
  struct AdjustVaultVars {
    price: u256,
    coll_change: u256,
    net_debt_change: u256,
    is_coll_ncrease: u256,
    debt: u256,
    coll: u256,
    old_icr: u256,
    new_icr: u256,
    new_trc: u256,
    usdm_fee: u256,
    new_debt: u256,
    new_coll: u256,
    stake: u256
  }

  #[derive(Drop, Clone, Serde, starknet::Store)]
  struct OpenVaultVars {
    price: u256,
    usdm_fee: u256,
    new_debt: u256,
    composite-debt: u256,
    icr: u256,
    nicr: u256,
    stake: u256,
    array_index: u256,
  }

  enum BorrowerOperation {
    OpenVault,
    CloseVault,
    AdjustVault
  }

  // --- Events ---
  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    ActivePoolAddressChanged: ActivePoolAddressChanged,
    DefaultPoolAddressChanged: DefaultPoolAddressChanged,
    StabilityPoolAddressChanged: StabilityPoolAddressChanged,
    GasPoolAddressChanged: GasPoolAddressChanged,
    CollSurplusPoolAddressChanged: CollSurplusPoolAddressChanged,
    PriceFeedAddressChanged: PriceFeedAddressChanged,
    SortedVaultsAddressChanged: SortedVaultsAddressChanged,
    USDMTokenAddressChanged: USDMTokenAddressChanged,
    MartenStakingAddressChanged: MartenStakingAddressChanged,
    VaultCreated: VaultCreated,
    VaultUpdated: VaultUpdated,
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub vault_manager_address: ContractAddress
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
    pub coll_surplus_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct PriceFeedAddressChanged {
    pub price_feed_address: ContractAddress
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
  pub struct MartenStakingAddressChanged {
    pub marten_staking_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultCreated {
    pub borrower: ContractAddress,
    pub array_index: u256
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
    pub usdm_fee: u256
  }

  // --- Constructor ---
  #[constructor]
  fn constructor(ref self: ContractState, owner: ContractAddress) {
    assert(Zero::is_non_zero(@owner), 'Owner cannot be zero addres');
    self.ownable.initializer(owner);
  }

  #[abi(embed_v0)]
  impl BorrowerOperationsImpl of IBorrowerOperations<ContractState> {
    fn set_addresses(
      ref self: ContractState,
      vault_manager_address: ContractAddress,
      active_pool_address: ContractAddress,
      default_pool_address: ContractAddress,
      stability_pool_address: ContractAddress,
      gas_pool_address: ContractAddress,
      coll_surplus_pool_address: ContractAddress,
      price_feed_address: ContractAddress,
      sorted_vaults_address: ContractAddress,
      usdm_token_address: ContractAddress,
      marten_staking_address: ContractAddress
    ) {
      self.ownable.assert_only_owner();

      assert(Zero::is_non_zero(@vault_manager_address), 'BO:VAULT_MANAGER_ZERO');
      assert(Zero::is_non_zero(@active_pool_address), 'BO:ACTIVE_POOL_ZERO');
      assert(Zero::is_non_zero(@default_pool_address), 'BO:DEFAULT_POOL_ZERO');
      assert(Zero::is_non_zero(@stability_pool_address), 'BO:STABILITY_POOL_ZERO');
      assert(Zero::is_non_zero(@gas_pool_address), 'BO:GAS_POOL_ZERO');
      assert(Zero::is_non_zero(@coll_surplus_pool_address), 'BO:COLL_SURPLUS_ZERO');
      assert(Zero::is_non_zero(@price_feed_address), 'BO:PRICE_FEED_ZERO');
      assert(Zero::is_non_zero(@sorted_vaults_address), 'BO:SORTED_VAULTS_ZERO');
      assert(Zero::is_non_zero(@usdm_token_address), 'BO:USDM_TOKEN_ZERO');
      assert(Zero::is_non_zero(@marten_staking_address), 'BO:MARTEN_STK_ZERO');

      self.stability_pool_address.write(stability_pool_address);
      self.gas_pool_address.write(gas_pool_address);
      self.marten_staking_address.write(marten_staking_address);

      self.vault_manager.write(IVaultManagerDispatcher { contract_address: vault_manager_address });
      self.active_pool.write(IActivePoolDispatcher { contract_address: active_pool_address });
      self.coll_surplus_pool.write(ICollSurplusPoolDispatcher { contract_address: coll_surplus_pool_address });
      self.marten_staking.write(IMartenStakingDispatcher { contract_address: marten_staking_address });
      self.usdm_token.write(IUSDMTokenDispatcher { contract_address: usdm_token_address });
      self.sorted_vaults.write(ISortedVaultsDispatcher { contract_address: sorted_vaults_address });

      self.emit(VaultManagerAddressChanged { vault_manager_address });
      self.emit(ActivePoolAddressChanged { active_pool_address });
      self.emit(DefaultPoolAddressChanged { default_pool_address} );
      self.emit(StabilityPoolAddressChanged { stability_pool_address });
      self.emit(GasPoolAddressChanged { gas_pool_address });
      self.emit(CollSurplusPoolAddressChanged { coll_surplus_pool_address });
      self.emit(PriceFeedAddressChanged { price_feed_address });
      self.emit(SortedVaultsAddressChanged { sorted_vaults_address });
      self.emit(USDMTokenAddressChanged { usdm_token_address });
      self.emit(MartenStakingAddressChanged { marten_staking_address });

      self.ownable.renounce_ownership();
    }

    fn open_vault(ref self: TContractState, max_fee: u256, usdm_mount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress) {}

    fn add_coll(ref self: TContractState, upper_hint: ContractAddress, lower_hint: ContractAddress);

    fn move_eth_gain_to_vault(ref self: TContractState, user: ContractAddress, upper_hint: ContractAddress, lower_hint: ContractAddress);

    fn withdraw_coll(ref self: TContractState, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

    fn withdraw_usdm(ref self: TContractState, maxFee: u256, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

    fn repay_usdm(ref self: TContractState, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

    fn close_vault(ref self: TContractState);

    fn adjust_vault(ref self: TContractState, max_fee: u256, coll_withdrawal: u256, debt_change: u256, is_debt_increase: bool, upper_hint: ContractAddress, lower_hint: ContractAddress);

    fn claim_collateral(ref self: TContractState);

    fn get_composite_debt(self: @TContractState, debt: u256) -> u256;
  }

  // --- 'require' functions ---
}
