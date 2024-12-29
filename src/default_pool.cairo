#[starknet::contract]
pub mod DefaultPool {
  use starknet::{ContractAddress, get_caller_address};
  use core::num::traits::Zero;
  use openzeppelin::access::ownable::OwnableComponent;
  use marten::interfaces::default_pool::IDefaultPool;
  use marten::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};

  component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

  #[abi(embed_v0)]
  impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
  impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

  #[storage]
  struct Storage {
    #[substorage(v0)]
    ownable: OwnableComponent::Storage,
    pub active_pool_address: ContractAddress,
    pub eth_token_address: ContractAddress,
    pub vault_manager_address: ContractAddress,
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
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    ActivePoolAddressChanged: ActivePoolAddressChanged,
    DefaultPoolUSDMDebtUpdated: DefaultPoolUSDMDebtUpdated,
    DefaultPoolETHBalanceUpdated: DefaultPoolETHBalanceUpdated,
    EtherSent: EtherSent,
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
  pub struct DefaultPoolUSDMDebtUpdated {
    pub usdm_debt: u256
  }

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolETHBalanceUpdated {
    pub amount: u256
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
  impl DefaultPoolImpl of IDefaultPool<ContractState> {
    fn set_addresses(
      ref self: ContractState,
      vault_manager_address: ContractAddress,
      active_pool_address: ContractAddress,
      eth_token_address: ContractAddress
    ) {
      self.ownable.assert_only_owner();

      assert(Zero::is_non_zero(@vault_manager_address), 'DP:VAULT_MANAGER_ZERO');
      assert(Zero::is_non_zero(@active_pool_address), 'DP:ACTIVE_POOL_ZERO');
      assert(Zero::is_non_zero(@eth_token_address), 'DP:ETH_ADDRESS_ZERO');

      self.vault_manager_address.write(vault_manager_address);
      self.active_pool_address.write(active_pool_address);
      self.eth_token_address.write(eth_token_address);

      self.emit(VaultManagerAddressChanged { vault_manager_address });
      self.emit(ActivePoolAddressChanged { active_pool_address });

      self.ownable.renounce_ownership();
    }

    fn deposit_eth(ref self: ContractState, amount: u256) {
      self.require_caller_is_active_pool();
      self.eth.write(self.eth.read() + amount);
      self.emit(DefaultPoolETHBalanceUpdated { amount: self.eth.read() });
    }

    fn get_eth(self: @ContractState) -> u256 {
      return self.eth.read();
    }

    fn get_usdm_debt(self: @ContractState) -> u256 {
      return self.usdm_debt.read();
    }

    fn send_eth_to_active_pool(ref self: ContractState, amount: u256) {
      self.require_caller_is_vault_manager();

      self.eth.write(self.eth.read() - amount);

      self.emit(DefaultPoolETHBalanceUpdated { amount: self.eth.read() });
      self.emit(EtherSent { to: self.active_pool_address.read(), amount });

      let eth_token: IERC20Dispatcher = IERC20Dispatcher { contract_address: self.eth_token_address.read() };
      let success = eth_token.transfer(self.active_pool_address.read(), amount);
      assert(success, 'DP:SEND_ETH_FAILED');
    }

    fn increase_usdm_debt(ref self: ContractState, amount: u256) {
      self.require_caller_is_vault_manager();
      self.usdm_debt.write(self.usdm_debt.read() + amount);
      self.emit(DefaultPoolUSDMDebtUpdated { usdm_debt: self.usdm_debt.read() });
    }

    fn decrease_usdm_debt(ref self: ContractState, amount: u256) {
      self.require_caller_is_vault_manager();
      self.usdm_debt.write(self.usdm_debt.read() - amount);
      self.emit(DefaultPoolUSDMDebtUpdated { usdm_debt: self.usdm_debt.read() });
    }
  }

  // --- 'require' functions ---
  #[generate_trait]
  pub impl RequireFunctions of RequireFunctionsTrait {
    fn require_caller_is_vault_manager(self: @ContractState) {
      let caller_address = get_caller_address();
      let vault_manager_address = self.vault_manager_address.read();
      assert(caller_address == vault_manager_address, 'DP:CALLER_IS_NOT_VM');
    }

    fn require_caller_is_active_pool(self: @ContractState) {
      let caller_address = get_caller_address();
      let active_pool_address = self.active_pool_address.read();
      assert(caller_address == active_pool_address, 'DP:CALLER_IS_NOT_AP');
    }
  }
}
