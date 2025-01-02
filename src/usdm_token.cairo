#[starknet::contract]
pub mod USDMToken {
  use openzeppelin_token::erc20::interface::IERC20;
  use core::num::traits::Zero;
  use starknet::{ContractAddress, get_caller_address, get_contract_address};
  use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
  use openzeppelin_utils::cryptography::nonces::NoncesComponent;
  use openzeppelin::access::ownable::OwnableComponent;
  use marten::interfaces::usdm_token::IUSDMToken;
  use openzeppelin_utils::snip12::SNIP12Metadata;

  component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
  component!(path: ERC20Component, storage: erc20, event: ERC20Event);
  component!(path: NoncesComponent, storage: nonces, event: NoncesEvent);

  #[abi(embed_v0)]
  impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
  impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

  #[abi(embed_v0)]
  impl ERC20PermitImpl = ERC20Component::ERC20PermitImpl<ContractState>;
  impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

  #[storage]
  struct Storage {
    #[substorage(v0)]
    ownable: OwnableComponent::Storage,
    #[substorage(v0)]
    erc20: ERC20Component::Storage,
    #[substorage(v0)]
    nonces: NoncesComponent::Storage,
    pub borrower_operations_address: ContractAddress,
    pub vault_manager_address: ContractAddress,
    pub stability_pool_address: ContractAddress,
  }

  // --- Events ---
  #[event]
  #[derive(Drop, starknet::Event)]
  enum Event {
    #[flat]
    OwnableEvent: OwnableComponent::Event,
    #[flat]
    ERC20Event: ERC20Component::Event,
    #[flat]
    NoncesEvent: NoncesComponent::Event,
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    StabilityPoolAddressChanged: StabilityPoolAddressChanged,
    BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
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
  pub struct BorrowerOperationsAddressChanged {
    pub borrower_operations_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMTokenBalanceUpdated {
    pub user: ContractAddress,
    pub amount: u256
  }

  // --- Constants ---
  #[constructor]
  fn constructor(ref self: ContractState) {
    self.erc20.initializer("USDM Stablecoin", "USDM");
  }

  fn increase_allowance(ref self: ContractState, spender: ContractAddress, added_amount: u256) -> bool{
    let current_allowance = self.erc20.allowance(get_caller_address(), spender);
    self.erc20.approve(spender, current_allowance + added_amount);
    true
  }

  fn decrease_allowance(ref self: ContractState, spender: ContractAddress, strubtracted_amount: u256) -> bool{
    let current_allowance = self.erc20.allowance(get_caller_address(), spender);
    self.erc20.approve(spender, current_allowance - strubtracted_amount);
    true
  }

  impl SNIP12MetadataImpl of SNIP12Metadata {
    fn name() -> felt252 {
      'USDM Stablecoin'
    }
    fn version() -> felt252 {
      'v1'
    }
  }

  #[abi(embed_v0)]
  impl USDMTokenImpl of IUSDMToken<ContractState> {
    fn set_addresses(ref self: ContractState, borrower_operations_address: ContractAddress, vault_manager_address: ContractAddress, stability_pool_address: ContractAddress) {
      self.ownable.assert_only_owner();

      assert(!vault_manager_address.is_zero(), 'USDM:VM_ZERO');
      assert(!stability_pool_address.is_zero(), 'USDM:SP_ZERO');
      assert(!borrower_operations_address.is_zero(), 'USDM:BO_ZERO');

      self.borrower_operations_address.write(borrower_operations_address);
      self.vault_manager_address.write(vault_manager_address);
      self.stability_pool_address.write(stability_pool_address);

      self.emit(BorrowerOperationsAddressChanged { borrower_operations_address });
      self.emit(VaultManagerAddressChanged { vault_manager_address });
      self.emit(StabilityPoolAddressChanged { stability_pool_address });

      self.ownable.renounce_ownership();
    }

    fn mint(ref self: ContractState, account: ContractAddress, amount: u256) {
      self.require_valid_recipient(account);
      self.erc20.mint(account, amount);
    }

    fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
      self.require_caller_is_BO_or_VM_or_SP();
      self.erc20.burn(account, amount);
    }

    fn send_to_pool(ref self: ContractState, sender: ContractAddress, pool_address: ContractAddress, amount: u256) {
      self.require_caller_is_SP();
      self.transfer_from(sender, pool_address, amount);
    }

    fn return_from_pool(ref self: ContractState, pool_address: ContractAddress, recipient: ContractAddress, amount: u256) {
      self.require_caller_is_VM_or_SP();
      self.transfer_from(pool_address, recipient, amount);
    }
  }

  #[abi(embed_v0)]
  impl ERC20InterfaceImpl of IERC20<ContractState> {
    fn total_supply(self: @ContractState) -> u256 {
      self.erc20.total_supply()
    }

    fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
      self.erc20.balance_of(account)
    }

    fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
      self.erc20.allowance(owner, spender)
    }

    fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
      self.require_valid_recipient(recipient);
      self.erc20.transfer(recipient, amount);
      true
    }

    fn transfer_from(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
      self.require_valid_recipient(recipient);
      self.erc20.transfer_from(sender, recipient, amount);
      true
    }

    fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
      self.erc20.approve(spender, amount);
      true
    }
  }

  #[generate_trait]
  impl RequireFunctions of RequireFunctionsTrait {
    // --- 'require' functions ---
    fn require_valid_recipient(self: @ContractState, recipient: ContractAddress) {
      assert(
        !recipient.is_zero() && recipient != get_contract_address(),
        'USDM:INVALID_RECIPIENT'
      );

      assert(
        recipient != self.borrower_operations_address.read() &&
        recipient != self.stability_pool_address.read() &&
        recipient != self.vault_manager_address.read(),
        'USDM:INVALID_RECIPIENT_2'
      );
    }

    fn require_caller_is_BO(self: @ContractState) {
      let caller = get_caller_address();
      assert(
        caller == self.borrower_operations_address.read(),
        'USDM:CALLER_NOT_BO'
      );
    }

    fn require_caller_is_BO_or_VM_or_SP(self: @ContractState) {
      let caller = get_caller_address();
      assert(
        caller == self.borrower_operations_address.read() ||
        caller == self.vault_manager_address.read() ||
        caller == self.stability_pool_address.read(),
        'USDM:CALLER_NOT_BO_VM_SP'
      );
    }

    fn require_caller_is_SP(self: @ContractState) {
      let caller = get_caller_address();
      assert(
        caller == self.stability_pool_address.read(),
        'USDM:CALLER_NOT_SP'
      );
    }

    fn require_caller_is_VM_or_SP(self: @ContractState) {
      let caller = get_caller_address();
      assert(
        caller == self.vault_manager_address.read() ||
        caller == self.stability_pool_address.read(),
        'USDM:CALLER_NOT_VM_SP'
      );
    }
  }
}
