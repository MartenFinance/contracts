#[starknet::contract]
pub mod ActivePool {
  use starknet::{ContractAddress, get_caller_address};
  use core::num::traits::Zero;
  use openzeppelin::access::ownable::OwnableComponent;
  use marten::interfaces::active_pool::IActivePool;
  use marten::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};

  component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

  #[abi(embed_v0)]
  impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
  impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

  #[storage]
  struct Storage {
    #[substorage(v0)]
    ownable: OwnableComponent::Storage,
    pub borrower_operations_address: ContractAddress,
    pub vault_manager_address: ContractAddress,
    pub stability_pool_address: ContractAddress,
    pub default_pool_address: ContractAddress,
    eth_token: IERC20Dispatcher,
    // deposited ether tracker
    eth: u256,
    usdm_debt: u256
  }

  // --- Events ---
  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    #[flat]
    OwnableEvent: OwnableComponent::Event,
    BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    StabilityPoolAddressChanged: StabilityPoolAddressChanged,
    DefaultPoolAddressChanged: DefaultPoolAddressChanged,
    ActivePoolUSDMDebtUpdated: ActivePoolUSDMDebtUpdated,
    ActivePoolETHBalanceUpdated: ActivePoolETHBalanceUpdated,
    EtherSent: EtherSent,
  }

  #[derive(starknet::Event, Drop)]
  pub struct BorrowerOperationsAddressChanged {
    pub borrower_operations_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub vault_manager_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct StabilityPoolAddressChanged {
    pub stability_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolAddressChanged {
    pub default_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolUSDMDebtUpdated {
    pub amount: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolETHBalanceUpdated {
    pub amount: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct EtherSent {
    pub to: ContractAddress,
    pub amount: u256
  }

  // --- Constructor ---
  #[constructor]
  fn constructor(ref self: ContractState, owner: ContractAddress, eth_address: ContractAddress) {
    assert(Zero::is_non_zero(@owner), 'Owner cannot be zero addres');
    self.ownable.initializer(owner);
    self.eth_token.write(IERC20Dispatcher { contract_address: eth_address });
  }

  // --- 'require' functions ---

  // Caller is Borrower Operations or Default Pool
  fn _require_caller_is_BO_or_DP(self: @ContractState) {
    let caller = get_caller_address();
    assert(
      caller == self.borrower_operations_address.read() ||
      caller == self.default_pool_address.read(),
    'AP:CALLER_IS_BO_OR_DP');
  }

  // Caller is Borrower Operations or Vault Manager or Stability Pool
  fn _require_caller_is_BO_or_VM_or_SP(self: @ContractState) {
    let caller = get_caller_address();
    assert(
      caller == self.borrower_operations_address.read() ||
      caller == self.vault_manager_address.read() ||
      caller == self.stability_pool_address.read(),
    'AP:CALLER_IS_BO_OR_VM_OR_SP');
  }

  // Caller is Borrower Operations or Vault Manager
  fn _require_caller_is_BO_or_VM(self: @ContractState) {
    let caller = get_caller_address();
    assert(
      caller == self.borrower_operations_address.read() ||
      caller == self.vault_manager_address.read(),
    'AP:CALLER_IS_BO_OR_VM');
  }

  #[abi(embed_v0)]
  impl ActivePoolImpl of IActivePool<ContractState> {
    fn set_addresses(
      ref self: ContractState,
      borrower_operations_address: ContractAddress,
      vault_manager_address: ContractAddress,
      stability_pool_address: ContractAddress,
      default_pool_address: ContractAddress
    ) {
        self.ownable.assert_only_owner();

        assert(Zero::is_non_zero(@borrower_operations_address), 'AP:BORROWER_OPERATIONS_ZERO');
        assert(Zero::is_non_zero(@vault_manager_address), 'AP:VAULT_MANAGER_ZERO');
        assert(Zero::is_non_zero(@stability_pool_address), 'AP:STABILITY_POOL_ZERO');
        assert(Zero::is_non_zero(@default_pool_address), 'AP:DEFAULT_POOL_ZERO');

        self.borrower_operations_address.write(borrower_operations_address);
        self.vault_manager_address.write(vault_manager_address);
        self.stability_pool_address.write(stability_pool_address);
        self.default_pool_address.write(default_pool_address);

        self.emit(BorrowerOperationsAddressChanged { borrower_operations_address });
        self.emit(VaultManagerAddressChanged { vault_manager_address });
        self.emit(StabilityPoolAddressChanged { stability_pool_address });
        self.emit(DefaultPoolAddressChanged { default_pool_address} );

        self.ownable.renounce_ownership();
    }

    fn get_eth (self: @ContractState) -> u256 {
      return self.eth.read();
    }

    fn get_usdm_debt(self: @ContractState) -> u256 {
      return self.usdm_debt.read();
    }

    fn deposit_eth(ref self: ContractState, amount: u256) {
      _require_caller_is_BO_or_DP(@self);
      self.eth.write(self.eth.read() + amount);

      self.emit(ActivePoolETHBalanceUpdated { amount: self.eth.read() });
    }

    fn send_eth(ref self: ContractState, recipient: ContractAddress, amount: u256) {
      _require_caller_is_BO_or_VM_or_SP(@self);
      self.eth.write(self.eth.read() - amount);

      self.emit(ActivePoolETHBalanceUpdated { amount: self.eth.read() });
      self.emit(EtherSent { to: recipient, amount });

      self.eth_token.read().transfer(recipient, amount);
    }

    fn increase_usdm_debt(ref self: ContractState, amount: u256) {
      _require_caller_is_BO_or_VM(@self);
      self.usdm_debt.write(self.usdm_debt.read() + amount);

      self.emit(ActivePoolUSDMDebtUpdated { amount: self.usdm_debt.read() });
    }

    fn decrease_usdm_debt(ref self: ContractState, amount: u256) {
      _require_caller_is_BO_or_VM_or_SP(@self);
      self.usdm_debt.write(self.usdm_debt.read() - amount);

      self.emit(ActivePoolUSDMDebtUpdated { amount: self.usdm_debt.read() });
    }
  }
}
