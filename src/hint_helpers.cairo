#[starknet::contract]
pub mod HintHelpers {
  use starknet::{ContractAddress, get_caller_address};
  use core::keccak::keccak_u256s_be_inputs;
  use openzeppelin::access::ownable::OwnableComponent;
  use marten::interfaces::marten_base::{IMartenBaseDispatcher, IMartenBaseDispatcherTrait};
  use marten::marten_math::{IMartenMathDispatcher, IMartenMathDispatcherTrait};
  use marten::interfaces::sorted_vaults::{ISortedVaultsDispatcher, ISortedVaultsDispatcherTrait};
  use marten::interfaces::vault_manager::{IVaultManagerDispatcher, IVaultManagerDispatcherTrait};

  component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

  #[abi(embed_v0)]
  struct Storage {
    #[substorage(v0)]
    ownable: OwnableComponent::Storage,
    pub marten_base_address: ContractAddress,
    pub sorted_vaults_address: ContractAddress,
    pub vault_manager_address: ContractAddress,
  }

  // --- Events ---
  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    #[flat]
    OwnableEvent: OwnableComponent::Event,
    SortedVaultsAddressChanged: SortedVaultsAddressChanged,
    VaultManagerAddressChanged: VaultManagerAddressChanged,
  }

  #[derive(starknet::Event, Drop)]
  pub struct SortedVaultsAddressChanged {
    pub sorted_vaults_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub vault_manager_address: ContractAddress
  }

  // --- Constants ---
  const DECIMAL_PRECISION: u256 = 1000000000000000000; // 1e18
  // Minimum collateral ratio for individual vaults
  pub const MCR: u256 = 1100000000000000000; // 110%

  // Minimum amount of net USDM debt a vault must have
  pub const MIN_NET_DEBT: u256 = 1800000000000000000000; // 1800e18;

  // --- Constructor ---
  #[constructor]
  fn constructor(ref self: ContractState, owner: ContractAddress) {
    assert(Zero::is_non_zero(@owner), 'Owner cannot be zero addres');
    self.ownable.initializer(owner);
  }

  #[abi(embed_v0)]
  impl HintHelpersImpl of IHintHelpers<ContractState> {
    fn set_addresses(
      ref self: ContractState,
      marten_base_address: ContractAddress,
      marten_math_address: ContractAddress,
      sorted_vaults_address: ContractAddress,
      vault_manager_address: ContractAddress,
    ) {
      self.ownable.assert_only_owner();

      assert(Zero::is_non_zero(@marten_base_address), 'HH:MARTEN_BASE_ZERO');
      assert(Zero::is_non_zero(@sorted_vaults_address), 'HH:SORTED_VAULTS_ZERO');
      assert(Zero::is_non_zero(@vault_manager_address), 'HH:VAULT_MANAGER_ZERO');

      self.storage.sorted_vaults_address.write(sorted_vaults_address);
      self.storage.vault_manager_address.write(vault_manager_address);

      self.ownable.renounce_ownership();
    }

    /// get_redemption_hints() - Helper function for finding the right hints to pass to redeem_collateral().
    ///
    /// It simulates a redemption of `usdm_amount` to figure out where the redemption sequence will start and what state the final Vault
    /// of the sequence will end up in.
    ///
    /// Returns three hints:
    /// - `first_redemption_hint` is the address of the first Vault with ICR >= MCR (i.e. the first Vault that will be redeemed).
    /// - `partial_redemption_hint_icr` is the final nominal ICR of the last Vault of the sequence after being hit by partial redemption,
    ///    or zero in case of no partial redemption.
    /// - `truncated_usdm_amount` is the maximum amount that can be redeemed out of the the provided `usdm_amount`. This can be lower than
    /// `usdm_amount` when redeeming the full amount would leave the last Vault of the redemption sequence with less net debt than the
    ///   minimum allowed value (i.e. MIN_NET_DEBT).
    ///
    /// The number of Vaults to consider for redemption can be capped by passing a non-zero value as `max_iterations`, while passing zero
    /// will leave it uncapped.
    ///
    fn get_redemption_hints(self: @ContractAddress, usdm_amount: u256, price: u256, max_iterations: u256) -> (ContractAddress, u256, u256) {
      let marten_base_contract: IMartenBaseDispatcher = IMartenBaseDispatcher { contract: self.marten_base_address.read() };
      let marten_math_contract: IMartenMathDispatcher = IMartenMathDispatcher { contract: self.marten_math_address.read() };
      let sorted_vault_contract: ISortedVaultsDispatcher = ISortedVaultsDispatcher { contract: self.sorted_vaults_address.read() };
      let vault_manager_contract: IVaultManagerDispatcher = IVaultManagerDispatcher { contract: self.vault_manager_address.read() };

      let mut current_vault_user: ContractAddress = sorted_vault_contract.get_last();
      let mut remaining_usdm: u256 = usdm_amount;
      let partial_redemption_hint_icr: u256 = 0;

      while (Zero::is_none_zero(@current_vault_user) && vault_manager_contract.get_current_icr(current_vault_user, price) < MCR) {
        current_vault_user = sorted_vault_contract.get_prev(current_vault_user);
      }

      let first_redemption_hint = current_vault_user;

      if (max_iterations == 0) {
        max_iterations = -1;
      }

      while (Zero::is_none_zero(@current_vault_user) && remaining_usdm > 0 && max_iterations-- > 0) {
        let net_usdm_debt = marten_base_contract.get_net_debt(vault_manager_contract.get_vault_debt(current_vault_user)) + vault_manager_contract.get_pending_usdm_debt_reward(current_vault_user);

        if (net_usdm_debt > remaining_usdm) {
          if (net_usdm_debt > MIN_NET_DEBT) {
            let max_redeemable_usdm = marten_math_contract.min(remaining_usdm, net_usdm_debt - MIN_NET_DEBT);

            let eth = vault_manager_contract.get_vault_coll(current_vault_user) + vault_manager_contract.get_pending_eth_reward(current_vault_user);
            let new_coll = eth - (max_redeemable_usdm * DECIMAL_PRECISION / price);
            let new_debt = net_usdm_debt - max_redeemable_usdm;

            let composite_debt = marten_base_contract.get_composite_debt(new_debt);
            partial_redemption_hint_icr = marten_math_contract.compute_nominal_cr(new_coll, composite_debt);

            remaining_usdm -= max_redeemable_usdm;
          }
          break;
        } else {
          remaining_usdm -= net_usdm_debt;
        }

        current_vault_user = sorted_vault_contract.get_prev(current_vault_user);
      }

      let truncated_usdm_amount = usdm_amount - remaining_usdm;

      return (first_redemption_hint, partial_redemption_hint_icr, truncated_usdm_amount);
    }

    ///
    ///  get_approx_hint() - return address of a Vault that is, on average, (length / num_trials) positions away in the
    /// sortedVaults list from the correct insert position of the Vault to be inserted.
    ///
    /// Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function
    /// is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:
    ///
    /// Submitting num_trials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will
    /// be <= sqrt(length) positions away from the correct insert position.
    ///
    fn get_approx_hint(self: @ContractAddress, cr: u256, num_trials: u256, input_random_seed: u256) -> (ContractAddress, u256, u256) {
      let vault_manager_contract: IVaultManagerDispatcher = IVaultManagerDispatcher { contract: self.vault_manager_address.read() };
      let marten_math_contract: IMartenMathDispatcher = IMartenMathDispatcher { contract: self.marten_math_address.read() };

      let array_length = vault_manager_contract.get_vault_owners_count();

      if (array_length == 0) {
        return (Zero, 0, input_random_seed);
      }

      let mut hint_address: ContractAddress = vault_manager_contract.get_last();
      let mut diff: u256 = marten_math_contract.get_absolute_difference(cr, vault_manager_contract.get_nominal_icr(hint_address));
      let mut latest_random_seed: u256 = input_random_seed;

      let mut i: u256 = 1;

      while (i < num_trials) {
        latest_random_seed = keccak_u256s_be_inputs(latest_random_seed);

        let array_index: u256 = latest_random_seed % array_length;
        let current_address: ContractAddress = vault_manager_contract.get_trove_from_trove_owners_array(array_index);
        let current_nicr: u256 = vault_manager_contract.get_nominal_icr(current_address);

        // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
        let current_diff: u256 = marten_math_contract.get_absolute_difference(current_nicr, cr);

        if (current_diff < diff) {
          diff = current_diff;
          hint_address = current_address;
        }
        i++;
      }
    }

    fn compute_nominal_cr(self: @ContractAddress, coll: u256, debt: u256) {
      let marten_math_contract: IMartenMathDispatcher = IMartenMathDispatcher { contract: self.marten_math_address.read() };
      return marten_math_contract.compute_nominal_cr(coll, debt);
    }

    fn compute_cr(self: @ContractAddress, coll: u256, debt: u256, price: u256) {
      let marten_math_contract: IMartenMathDispatcher = IMartenMathDispatcher { contract: self.marten_math_address.read() };
      return marten_math_contract.compute_cr(coll, debt, price);
    }
  }
}
