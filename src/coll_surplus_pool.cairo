#[starknet::contract]
pub mod CollSurPlusPool {
  use starknet::{ContractAddress, get_caller_address};
  use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
  use core::num::traits::Zero;
  use openzeppelin::access::ownable::OwnableComponent;
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
    pub active_pool_address: ContractAddress,
    pub eth_token_address: ContractAddress,
    // deposited ether tracker
    eth: u256,
    // Collateral surplus claimable by trove owners
    balances: Map::<ContractAddress, u256>,
  }

  // --- Events ---
  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    #[flat]
    OwnableEvent: OwnableComponent::Event,
    BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    ActivePoolAddressChanged: ActivePoolAddressChanged,
    CollBalanceUpdated: CollBalanceUpdated,
    EtherSent: EtherSent
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
  pub struct ActivePoolAddressChanged {
    pub active_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct CollBalanceUpdated {
    pub account: ContractAddress,
    pub new_balance: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct EtherSent {
    pub to: ContractAddress,
    pub amount: u256
  }

  // --- Constructor ---
  #[constructor]
  fn constructor(ref self: ContractState, owner: ContractAddress) {
    assert(Zero::is_non_zero(@owner), 'Owner cannot be zero addres');
    self.ownable.initializer(owner);
  }

  #[abi(embed_v0)]
  impl CollSurPlusPoolImpl of ICollSurplusPool<ContractState> {
    fn set_addresses (
      ref self: ContractState,
      borrower_operations_address: ContractAddress,
      vault_manager_address: ContractAddress,
      active_pool_address: ContractAddress,
      eth_token_address: ContractAddress
    ) {
      self.ownable.assert_only_owner();

      assert(Zero::is_non_zero(@borrower_operations_address), 'CSP:BORROWER_OPERATIONS_ZERO');
      assert(Zero::is_non_zero(@vault_manager_address), 'CSP:VAULT_MANAGER_ZERO');
      assert(Zero::is_non_zero(@active_pool_address), 'CSP:ACTIVE_POOL_ZERO');
      assert(Zero::is_non_zero(@eth_token_address), 'CSP:ETH_ADDRESS_ZERO');

      self.borrower_operations_address.write(borrower_operations_address);
      self.vault_manager_address.write(vault_manager_address);
      self.active_pool_address.write(active_pool_address);
      self.eth_token_address.write(eth_token_address);

      self.emit(BorrowerOperationsAddressChanged { borrower_operations_address });
      self.emit(VaultManagerAddressChanged { vault_manager_address });
      self.emit(ActivePoolAddressChanged { active_pool_address });

      self.ownable.renounce_ownership();
    }

    fn deposit_eth(ref self: ContractState, amount: u256) {
      self.require_caller_is_active_pool();
      self.eth.write(self.eth.read() + amount);
    }

    fn get_eth(self: @ContractState) -> u256 {
      return self.eth.read();
    }

    fn get_collateral(self: @ContractState, account: ContractAddress) -> u256 {
      return  self.balances.read(account);
    }

    fn account_surplus(ref self: ContractState, account: ContractAddress, amount: u256) {
      self.require_caller_is_vault_manager()

      let new_amount: u256 = self.balances.read(account) + amount;
      self.balances.write(account, new_amount);

      self.emit(CollBalanceUpdated { account, new_balance: new_amount });
    }

    fn claim_coll(ref self: ContractState, account: ContractAddress) {
      self.require_caller_is_borrower_operations();

      let claimable_coll: u256 = self.balances.read(account);
      assert(claimable_coll > 0, "CSP:NO_COLLATERAL_AVAILABLE");

      self.balances.write(account, 0);
      self.emit(CollBalanceUpdate { account, new_balance: 0 });

      self.eth.write(self.eth.read() - claimable_coll);
      self.emit(EtherSent { to: account, amount: claimable_coll });

      let eth_token: IERC20Dispatcher = IERC20Dispatcher { contract_address: self.eth_token_address.read() };
      let success = eth_token.transfer(account, claimable_coll);
      assert(success, 'CSO:SEND_ETH_FAILED');
    }
  }

  // --- 'require' functions ---
  #[generate_trait]
  pub impl RequireFunctions of RequireFunctionsTrait {
    fn require_caller_is_borrower_operations(self: @ContractState) {
      let caller_address = get_caller_address();
      let borrower_operations_address = self.borrower_operations_address.read();
      assert(caller_address == borrower_operations_address, "CSP:CALLER_IS_NOT_BO");
    }

    fn require_caller_is_vault_manager() {
      let caller_address = get_caller_address(self: @ContractState);
      let vault_manager_address = self.vault_manager_address.read();
      assert(caller_address == vault_manager_address, "CSP:CALLER_IS_NOT_VM");
    }

    fn require_caller_is_active_pool() {
      let caller_address = get_caller_address(self: @ContractState);
      let active_pool_address = self.active_pool_address.read();
      assert(caller_address == active_pool_address, "CSP:CALLER_IS_NOT_AP");
    }
  }
}
