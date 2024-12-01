#[starknet::contract]
pub mod ActivePool {
  use starknet::{ContractAddress};
  use core::num::traits::Zero;
  use openzeppelin::access::ownable::OwnableComponent;

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
    // deposited ether tracker
    eth: u256,
    usdm_debt: u256
  }

  // --- Events ---
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
    pub usdm_debt: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolETHBalanceUpdated {
    pub amount: u256
  }

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
  }

  // --- Constructor ---
  #[constructor]
  fn constructor(ref self: ContractState, owner: ContractAddress) {
    assert(Zero::is_non_zero(@owner), 'Owner cannot be zero addres');
    self.ownable.initializer(owner);
  }

  // --- Contract setters ---
  fn set_addresses(
    ref self: ContractState,
    borrower_operations_address: ContractAddress,
    vault_manager_address: ContractAddress,
    stability_pool_address: ContractAddress,
    default_pool_address: ContractAddress) {
      self.ownable.assert_only_owner();

      assert(Zero::is_non_zero(@borrower_operations_address), 'BORROWER_OPERATIONS_ZERO');
      assert(Zero::is_non_zero(@vault_manager_address), 'VAULT_MANAGER_ZERO');
      assert(Zero::is_non_zero(@stability_pool_address), 'STABILITY_POOL_ZERO');
      assert(Zero::is_non_zero(@default_pool_address), 'DEFAULT_POOL_ZERO');

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
}
