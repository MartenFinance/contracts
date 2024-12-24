#[starknet::contract]
pub mod BorrowerOperations {
  use starknet::{ContractAddress, get_caller_address};
  use core::num::traits::Zero;
  use openzeppelin::access::ownable::OwnableComponent;
  use marten::interfaces::active_pool::{IActivePoolDispatcher, IActivePoolDispatcherTrait};
  use marten::interfaces::borrower_operations::IBorrowerOperations;
  use marten::interfaces::coll_surplus_pool::{ICollSurplusPoolDispatcher};
  use marten::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
  use marten::interfaces::marten_base::{IMartenBaseDispatcher, IMartenBaseDispatcherTrait};
  use marten::marten_math::{IMartenMathDispatcher, IMartenMathDispatcherTrait};
  use marten::interfaces::marten_staking::{IMartenStakingDispatcher, IMartenStakingDispatcherTrait};
  use marten::interfaces::price_feed::{IPriceFeedDispatcher, IPriceFeedDispatcherTrait};
  use marten::interfaces::sorted_vaults::{ISortedVaultsDispatcher, ISortedVaultsDispatcherTrait};
  use marten::interfaces::usdm_token::{IUSDMTokenDispatcher, IUSDMTokenDispatcherTrait};
  use marten::interfaces::vault_manager::{IVaultManagerDispatcher, IVaultManagerDispatcherTrait};

  component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

  #[abi(embed_v0)]
  impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
  impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

  #[storage]
  struct Storage {
    #[substorage(v0)]
    ownable: OwnableComponent::Storage,
    active_pool_address: ContractAddress,
    coll_surplus_pool_address: ContractAddress,
    default_pool_address: ContractAddress,
    eth_token_address: ContractAddress,
    gas_pool_address: ContractAddress,
    marten_base_address: ContractAddress,
    marten_math_address: ContractAddress,
    marten_staking_address: ContractAddress,
    price_feed_address: ContractAddress,
    sorted_vaults_address: ContractAddress,
    stability_pool_address: ContractAddress,
    usdm_token_address: ContractAddress,
    vault_manager_address: ContractAddress
  }

  #[derive(Copy, Drop, Serde, Hash, starknet::Store)]
  struct AdjustVaultVars {
    price: u256,
    coll_change: u256,
    net_debt_change: u256,
    is_coll_increase: bool,
    debt: u256,
    coll: u256,
    old_icr: u256,
    new_icr: u256,
    new_tcr: u256,
    usdm_fee: u256,
    new_debt: u256,
    new_coll: u256,
    stake: u256
  }

  #[derive(Copy, Drop, Serde, Hash, starknet::Store)]
  struct OpenVaultVars {
    price: u256,
    usdm_fee: u256,
    net_debt: u256,
    composite_debt: u256,
    icr: u256,
    nicr: u256,
    stake: u256,
    array_index: u256,
  }

  #[derive(Drop, Serde)]
  enum BorrowerOperation {
    OpenVault,
    CloseVault,
    AdjustVault
  }

  // --- Events ---
  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    #[flat]
    OwnableEvent: OwnableComponent::Event,
    ActivePoolAddressChanged: ActivePoolAddressChanged,
    CollSurplusPoolAddressChanged: CollSurplusPoolAddressChanged,
    DefaultPoolAddressChanged: DefaultPoolAddressChanged,
    GasPoolAddressChanged: GasPoolAddressChanged,
    MartenStakingAddressChanged: MartenStakingAddressChanged,
    PriceFeedAddressChanged: PriceFeedAddressChanged,
    SortedVaultsAddressChanged: SortedVaultsAddressChanged,
    StabilityPoolAddressChanged: StabilityPoolAddressChanged,
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    USDMTokenAddressChanged: USDMTokenAddressChanged,
    USDMBorrowingFeePaid: USDMBorrowingFeePaid,
    VaultCreated: VaultCreated,
    VaultUpdated: VaultUpdated,
  }

  #[derive(starknet::Event, Drop)]
  pub struct ActivePoolAddressChanged {
    pub active_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct CollSurplusPoolAddressChanged {
    pub coll_surplus_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct DefaultPoolAddressChanged {
    pub default_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub vault_manager_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct GasPoolAddressChanged {
    pub gas_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct MartenStakingAddressChanged {
    pub marten_staking_address: ContractAddress
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
  pub struct StabilityPoolAddressChanged {
    pub stability_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMTokenAddressChanged {
    pub usdm_token_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMBorrowingFeePaid {
    pub borrower: ContractAddress,
    pub usdm_fee: u256
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
    pub operation: BorrowerOperation
  }

  // --- Constants ---
  const DECIMAL_PRECISION: u256 = 1000000000000000000; // 1e18
  pub const BORROWING_FEE_FLOOR: u256 = DECIMAL_PRECISION / 1000 * 5; // 0.5%

  // Minimum collateral ratio for individual troves
  pub const MCR: u256 = 1100000000000000000; // 110%

  // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
  pub const CCR: u256 = 1500000000000000000; // 150%

  // Minimum amount of net USDM debt a trove must have
  pub const MIN_NET_DEBT: u256 = 1800000000000000000000; // 1800e18;

  // Amount of USDM to be locked in gas pool on opening troves
  pub const USDM_GAS_COMPENSATION: u256 = 200000000000000000000; // 200e18;

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
      active_pool_address: ContractAddress,
      coll_surplus_pool_address: ContractAddress,
      default_pool_address: ContractAddress,
      eth_token_address: ContractAddress,
      gas_pool_address: ContractAddress,
      marten_base_address: ContractAddress,
      marten_math_address: ContractAddress,
      marten_staking_address: ContractAddress,
      price_feed_address: ContractAddress,
      sorted_vaults_address: ContractAddress,
      stability_pool_address: ContractAddress,
      usdm_token_address: ContractAddress,
      vault_manager_address: ContractAddress,
    ) {
      self.ownable.assert_only_owner();

      assert(Zero::is_non_zero(@active_pool_address), 'BO:ACTIVE_POOL_ZERO');
      assert(Zero::is_non_zero(@coll_surplus_pool_address), 'BO:COLL_SURPLUS_ZERO');
      assert(Zero::is_non_zero(@default_pool_address), 'BO:DEFAULT_POOL_ZERO');
      assert(Zero::is_non_zero(@eth_token_address), 'BO:ETH_ADDRESS_ZERO');
      assert(Zero::is_non_zero(@gas_pool_address), 'BO:GAS_POOL_ZERO');
      assert(Zero::is_non_zero(@marten_base_address), 'BO:MARTEN_BASE_ZERO');
      assert(Zero::is_non_zero(@marten_math_address), 'BO:MARTEN_MATH_ZERO');
      assert(Zero::is_non_zero(@marten_staking_address), 'BO:MARTEN_STK_ZERO');
      assert(Zero::is_non_zero(@price_feed_address), 'BO:PRICE_FEED_ZERO');
      assert(Zero::is_non_zero(@sorted_vaults_address), 'BO:SORTED_VAULTS_ZERO');
      assert(Zero::is_non_zero(@stability_pool_address), 'BO:STABILITY_POOL_ZERO');
      assert(Zero::is_non_zero(@usdm_token_address), 'BO:USDM_TOKEN_ZERO');
      assert(Zero::is_non_zero(@vault_manager_address), 'BO:VAULT_MANAGER_ZERO');

      self.active_pool_address.write(active_pool_address);
      self.coll_surplus_pool_address.write(coll_surplus_pool_address);
      self.default_pool_address.write(default_pool_address);
      self.eth_token_address.write(eth_token_address);
      self.gas_pool_address.write(gas_pool_address);
      self.marten_base_address.write(marten_base_address);
      self.marten_math_address.write(marten_math_address);
      self.marten_staking_address.write(marten_staking_address);
      self.price_feed_address.write(price_feed_address);
      self.sorted_vaults_address.write(sorted_vaults_address);
      self.stability_pool_address.write(stability_pool_address);
      self.usdm_token_address.write(usdm_token_address);
      self.vault_manager_address.write(vault_manager_address);

      self.emit(ActivePoolAddressChanged { active_pool_address });
      self.emit(CollSurplusPoolAddressChanged { coll_surplus_pool_address });
      self.emit(DefaultPoolAddressChanged { default_pool_address} );
      self.emit(GasPoolAddressChanged { gas_pool_address });
      self.emit(MartenStakingAddressChanged { marten_staking_address });
      self.emit(PriceFeedAddressChanged { price_feed_address });
      self.emit(SortedVaultsAddressChanged { sorted_vaults_address });
      self.emit(StabilityPoolAddressChanged { stability_pool_address });
      self.emit(USDMTokenAddressChanged { usdm_token_address });
      self.emit(VaultManagerAddressChanged { vault_manager_address });

      self.ownable.renounce_ownership();
    }

    fn open_vault(ref self: ContractState, max_fee_percentage: u256, eth_amount: u256, usdm_amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress) {
      let price_feed_contract: IPriceFeedDispatcher = IPriceFeedDispatcher { contract_address: self.price_feed_address.read() };
      let marten_base_contract: IMartenBaseDispatcher = IMartenBaseDispatcher { contract_address: self.marten_base_address.read() };

      let mut vars = OpenVaultVars {
        price: 0,
        usdm_fee: 0,
        net_debt: 0,
        composite_debt: 0,
        icr: 0,
        nicr: 0,
        stake: 0,
        array_index: 0,
      };

      vars.price = price_feed_contract.fetch_price();
      let is_recovery_mode: bool = marten_base_contract.check_recovery_mode(vars.price);

      InternalFunctionsTrait::require_valid_max_fee_percentage(max_fee_percentage, is_recovery_mode);
      InternalFunctionsTrait::require_vault_is_not_active(self.vault_manager_address.read(), get_caller_address());

      vars.net_debt = usdm_amount;

      if(!is_recovery_mode) {
        vars.usdm_fee = InternalFunctionsTrait::trigger_borrowing_fee(@self, usdm_amount, max_fee_percentage);
        vars.net_debt = vars.net_debt + vars.usdm_fee;
      }

      InternalFunctionsTrait::require_at_least_min_net_debt(vars.net_debt);

       // ICR is based on the composite debt, i.e. the requested USDM amount + USDM borrowing fee + USDM gas comp.
      vars.composite_debt = marten_base_contract.get_composite_debt(vars.net_debt);
      assert(vars.composite_debt > 0, 'BO:COMPOSITE_DEBT_LESS_THAN_0');

      let marten_math_contract: IMartenMathDispatcher = IMartenMathDispatcher { contract_address: self.marten_math_address.read() };
      vars.icr = marten_math_contract.compute_cr(eth_amount, vars.composite_debt, vars.price);
      vars.nicr = marten_math_contract.compute_nominal_cr(eth_amount, vars.composite_debt);

      if(is_recovery_mode) {
        InternalFunctionsTrait::require_icr_is_above_ccr(@self, vars.icr);
      } else {
        InternalFunctionsTrait::require_icr_is_above_mcr(@self, vars.icr);
        let new_tcr = InternalFunctionsTrait::get_new_tcr_from_vault_change(@self, eth_amount, true, vars.composite_debt, true, vars.price);
        InternalFunctionsTrait::require_icr_is_above_ccr(@self, new_tcr);
      }

      // Set the vault struct's properties
      let vault_manager_contract: IVaultManagerDispatcher = IVaultManagerDispatcher { contract_address: self.vault_manager_address.read() };
      let caller = get_caller_address();

      vault_manager_contract.set_vault_status(caller, 1);
      vault_manager_contract.increase_vault_coll(caller, eth_amount);
      vault_manager_contract.increase_vault_debt(caller, vars.composite_debt);
      vault_manager_contract.update_vault_reward_snapshots(caller);

      vars.stake = vault_manager_contract.update_stake_and_total_stakes(caller);

      let sorted_vaults_contract: ISortedVaultsDispatcher = ISortedVaultsDispatcher { contract_address: self.sorted_vaults_address.read() };
      sorted_vaults_contract.insert(caller, vars.nicr, upper_hint, lower_hint);
      vars.array_index = vault_manager_contract.add_vault_owner_to_array(caller);
      self.emit(VaultCreated { borrower: caller, array_index: vars.array_index });

      // Move the ether to the Active Pool, and mint the usdm_amount to the borrower
      InternalFunctions::active_pool_add_coll(@self, eth_amount);
      InternalFunctions::withdraw_usdm(@self, caller, usdm_amount, vars.net_debt);
      // Move the USDM gas compensation to the Gas Pool
      InternalFunctions::withdraw_usdm(@self, self.gas_pool_address.read(), USDM_GAS_COMPENSATION, USDM_GAS_COMPENSATION);

      self.emit(VaultUpdated { borrower: caller, debt: vars.composite_debt, coll: eth_amount, stake: vars.stake, operation: BorrowerOperation::OpenVault } );
      self.emit(USDMBorrowingFeePaid { borrower: caller, usdm_fee: vars.usdm_fee });
    }

    fn add_coll(ref self: ContractState, upper_hint: ContractAddress, lower_hint: ContractAddress) {}

    fn move_eth_gain_to_vault(ref self: ContractState, user: ContractAddress, upper_hint: ContractAddress, lower_hint: ContractAddress) {}

    fn withdraw_coll(ref self: ContractState, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress) {}

    fn withdraw_usdm(ref self: ContractState, maxFee: u256, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress) {}

    fn repay_usdm(ref self: ContractState, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress) {}

    fn close_vault(ref self: ContractState) {}

    fn adjust_vault(ref self: ContractState, max_fee: u256, coll_withdrawal: u256, debt_change: u256, is_debt_increase: bool, upper_hint: ContractAddress, lower_hint: ContractAddress) {}

    fn claim_collateral(ref self: ContractState) {}
  }

  #[generate_trait]
  pub impl InternalFunctions of InternalFunctionsTrait {

    // --- 'require' fns ---
    fn require_singular_coll_change(amount: u256, coll_withdrawal: u256) {
      assert(amount == 0 || coll_withdrawal == 0, 'BO:SINGULAR_COL_CHANGE');
    }

    fn require_caller_is_borrower(borrower: ContractAddress) {
      let caller = get_caller_address();
      assert(caller == borrower, 'BO:CALLER_IS_BORROWER');
    }

    fn require_non_zero_adjustment(amount: u256, coll_withdrawal: u256, usdm_change: u256) {
      assert(amount != 0 || coll_withdrawal != 0 || usdm_change != 0, 'BO:NON_ZERO');
    }

    fn require_vault_is_active(vault_manager_address: ContractAddress, borrower: ContractAddress) {
      let vault_manager_contract: IVaultManagerDispatcher = IVaultManagerDispatcher { contract_address: vault_manager_address };
      let status: u256 = vault_manager_contract.get_vault_status(borrower);
      assert(status == 1, 'BO:VAULT_NOT_EXIST');
    }

    fn require_vault_is_not_active(vault_manager_address: ContractAddress, borrower: ContractAddress)  {
      let vault_manager_contract: IVaultManagerDispatcher = IVaultManagerDispatcher { contract_address: vault_manager_address };
      let status: u256 = vault_manager_contract.get_vault_status(borrower);
      assert(status != 1, 'BO:TROVE_IS_ACTIVE');
    }

    fn require_non_zero_debt_change(usdm_change: u256) {
      assert(usdm_change > 0, 'BO:NON_ZERO_DEBT_CHANGE');
    }

    fn require_not_in_recovery_mode(self: @ContractState, price: u256) {
      let marten_base_contract: IMartenBaseDispatcher = IMartenBaseDispatcher { contract_address: self.marten_base_address.read() };
      assert(!marten_base_contract.check_recovery_mode(price), 'BO:IN_RECOVERY_MODE');
    }

    fn require_no_coll_withdrawal(self: @ContractState, coll_withdrawal: u256) {
      assert(coll_withdrawal == 0, 'BO:NO_COLL_WITHDRAWAL');
    }

    fn require_valid_adjustment_in_current_mode(
      self: @ContractState,
      is_recovery_mode: bool,
      coll_withdrawal: u256,
      is_debt_increase: bool,
      ref vars: AdjustVaultVars
    ) {
      if (is_recovery_mode) {
        self.require_no_coll_withdrawal(coll_withdrawal);
        if (is_debt_increase) {
          self.require_icr_is_above_ccr(vars.new_icr);
          self.require_new_icr_is_above_old_icr(vars.new_icr, vars.old_icr);
        }
      } else {
        self.require_icr_is_above_mcr(vars.new_icr);
        vars.new_tcr = self.get_new_tcr_from_vault_change(vars.coll_change, vars.is_coll_increase, vars.net_debt_change, is_debt_increase, vars.price);
        self.require_new_tcr_is_above_ccr(vars.new_tcr);
      }
    }

    fn require_icr_is_above_mcr(self: @ContractState, new_icr: u256) {
      assert(new_icr >= MCR, 'BO:ICR_IS_UNDER_MCR');
    }

    fn require_icr_is_above_ccr(self: @ContractState, new_icr: u256) {
      assert(new_icr >= CCR, 'BO:ICR_IS_UNDER_CCR');
    }

    fn require_new_icr_is_above_old_icr(self: @ContractState, new_icr: u256, old_icr: u256) {
      assert(new_icr >= old_icr, 'BO:DECREASE_ICR');
    }

    fn require_new_tcr_is_above_ccr(self: @ContractState, new_tcr: u256) {
      assert(new_tcr >= CCR, 'BO:NEW_TCR_IS_UNDER_CCR');
    }

    fn require_at_least_min_net_debt(net_debt: u256) {
      assert(net_debt >= MIN_NET_DEBT, 'BO:VAULT_NET_DEBT');
    }

    fn require_valid_usdm_repayment(current_debt: u256, debt_repayment: u256) {
      assert(debt_repayment <= current_debt - USDM_GAS_COMPENSATION, 'BO:INVALID_USDM_REPAYMENT');
    }

    fn require_caller_is_stability_pool(self: @ContractState) {
      let caller = get_caller_address();
      assert(caller == self.stability_pool_address.read(), 'BO:CALLER_IS_NOT_SP');
    }

    fn require_sufficient_usdm_balance(usdm_token_address: ContractAddress, borrower: ContractAddress, debt_repayment: u256) {
      let usdm_contract: IERC20Dispatcher = IERC20Dispatcher { contract_address: usdm_token_address };
      assert(usdm_contract.balance_of(borrower) >= debt_repayment, 'BO:INSUFFICIENT_USDM');
    }

    fn require_valid_max_fee_percentage(max_fee_percentage: u256, is_recovery_mode: bool) {
      if (is_recovery_mode) {
        assert(max_fee_percentage <= DECIMAL_PRECISION, 'BO:MAX_FEE_PERCENTAGE_TOO_LARGE');
      } else {
        assert(max_fee_percentage >= BORROWING_FEE_FLOOR && max_fee_percentage <= DECIMAL_PRECISION, 'BO:MAX_FEE_PERCENTAGE_OVERFLOW');
      }
    }

    // Helper functions ---
    fn trigger_borrowing_fee(self: @ContractState, usdm_amount: u256, max_fee_percentage: u256) -> u256 {
      let vault_manager_contract: IVaultManagerDispatcher = IVaultManagerDispatcher { contract_address: self.vault_manager_address.read() };
      let marten_base_contract: IMartenBaseDispatcher = IMartenBaseDispatcher { contract_address: self.marten_base_address.read() };

      vault_manager_contract.decay_base_rate_from_borrowing(); // decay the baseRate state variable
      let usdm_fee: u256 = vault_manager_contract.get_borrowing_fee(usdm_amount);

      marten_base_contract.require_user_accepts_fee(usdm_fee, usdm_amount, max_fee_percentage);

      // Send fee to Martend staking contract
      let marten_staking_contract: IMartenStakingDispatcher = IMartenStakingDispatcher { contract_address: self.marten_staking_address.read() };
      let usdm_contract: IUSDMTokenDispatcher = IUSDMTokenDispatcher { contract_address: self.usdm_token_address.read() };

      marten_staking_contract.increase_f_eth(usdm_fee);
      usdm_contract.mint(self.marten_staking_address.read(), usdm_fee);

      return usdm_fee;
  }

  // fn _getUSDValue(uint _coll, uint _price) internal pure returns (uint) {
  //     uint usdValue = _price.mul(_coll).div(DECIMAL_PRECISION);

  //     return usdValue;
  // }

  // fn _getCollChange(
  //     uint _collReceived,
  //     uint _requestedCollWithdrawal
  // )
  //     internal
  //     pure
  //     returns(uint collChange, bool isCollIncrease)
  // {
  //     if (_collReceived != 0) {
  //         collChange = _collReceived;
  //         isCollIncrease = true;
  //     } else {
  //         collChange = _requestedCollWithdrawal;
  //     }
  // }

  // // Update trove's coll and debt based on whether they increase or decrease
  // fn _updateTroveFromAdjustment
  // (
  //     ITroveManager _troveManager,
  //     address _borrower,
  //     uint _collChange,
  //     bool _isCollIncrease,
  //     uint _debtChange,
  //     bool _isDebtIncrease
  // )
  //     internal
  //     returns (uint, uint)
  // {
  //     uint newColl = (_isCollIncrease) ? _troveManager.increaseTroveColl(_borrower, _collChange)
  //                                     : _troveManager.decreaseTroveColl(_borrower, _collChange);
  //     uint newDebt = (_isDebtIncrease) ? _troveManager.increaseTroveDebt(_borrower, _debtChange)
  //                                     : _troveManager.decreaseTroveDebt(_borrower, _debtChange);

  //     return (newColl, newDebt);
  // }

  // fn _moveTokensAndETHfromAdjustment
  // (
  //     IActivePool _activePool,
  //     IUSDMToken _lusdToken,
  //     address _borrower,
  //     uint _collChange,
  //     bool _isCollIncrease,
  //     uint _USDMChange,
  //     bool _isDebtIncrease,
  //     uint _netDebtChange
  // )
  //     internal
  // {
  //     if (_isDebtIncrease) {
  //         _withdrawUSDM(_activePool, _lusdToken, _borrower, _USDMChange, _netDebtChange);
  //     } else {
  //         _repayUSDM(_activePool, _lusdToken, _borrower, _USDMChange);
  //     }

  //     if (_isCollIncrease) {
  //         _activePoolAddColl(_activePool, _collChange);
  //     } else {
  //         _activePool.sendETH(_borrower, _collChange);
  //     }
  // }

    // Send ETH to Active Pool and increase its recorded ETH balance
    fn active_pool_add_coll(self: @ContractState, amount: u256) {
      let eth_contract: IERC20Dispatcher = IERC20Dispatcher { contract_address: self.eth_token_address.read() };
      let success = eth_contract.transfer(self.active_pool_address.read(), amount);
      assert(success, 'BO:SEND_ETH_TO_AP_FAILED');
    }

    // Issue the specified amount of USDM to account and increases the total active debt (net_debt_increase potentially includes a USDMFee)
    fn withdraw_usdm(self: @ContractState, account: ContractAddress, usdm_amount: u256, net_debt_increase: u256) {
      let active_pool_contract: IActivePoolDispatcher = IActivePoolDispatcher { contract_address: self.active_pool_address.read() };
      let usdm_contract: IUSDMTokenDispatcher = IUSDMTokenDispatcher { contract_address: self.usdm_token_address.read() };

      active_pool_contract.increase_usdm_debt(net_debt_increase);
      usdm_contract.mint(account, usdm_amount);
    }

  // // Burn the specified amount of USDM from _account and decreases the total active debt
  // fn _repayUSDM(IActivePool _activePool, IUSDMToken _lusdToken, address _account, uint _USDM) internal {
  //     _activePool.decreaseUSDMDebt(_USDM);
  //     _lusdToken.burn(_account, _USDM);
  // }

   // ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    // fn _getNewNominalICRFromTroveChange
    // (
    //     uint _coll,
    //     uint _debt,
    //     uint _collChange,
    //     bool _isCollIncrease,
    //     uint _debtChange,
    //     bool _isDebtIncrease
    // )
    //     pure
    //     internal
    //     returns (uint)
    // {
    //     (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

    //     uint newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
    //     return newNICR;
    // }

    // // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    // fn _getNewICRFromTroveChange
    // (
    //     uint _coll,
    //     uint _debt,
    //     uint _collChange,
    //     bool _isCollIncrease,
    //     uint _debtChange,
    //     bool _isDebtIncrease,
    //     uint _price
    // )
    //     pure
    //     internal
    //     returns (uint)
    // {
    //     (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

    //     uint newICR = LiquityMath._computeCR(newColl, newDebt, _price);
    //     return newICR;
    // }

    // fn _getNewTroveAmounts(
    //     uint _coll,
    //     uint _debt,
    //     uint _collChange,
    //     bool _isCollIncrease,
    //     uint _debtChange,
    //     bool _isDebtIncrease
    // )
    //     internal
    //     pure
    //     returns (uint, uint)
    // {
    //     uint newColl = _coll;
    //     uint newDebt = _debt;

    //     newColl = _isCollIncrease ? _coll.add(_collChange) :  _coll.sub(_collChange);
    //     newDebt = _isDebtIncrease ? _debt.add(_debtChange) : _debt.sub(_debtChange);

    //     return (newColl, newDebt);
    // }

    fn get_new_tcr_from_vault_change(self: @ContractState, coll_change: u256, is_coll_in_crease: bool, debt_change: u256, is_debt_in_crease: bool, price: u256) -> u256 {
      // uint totalColl = getEntireSystemColl();
      // uint totalDebt = getEntireSystemDebt();

      // totalColl = _isCollIncrease ? totalColl.add(_collChange) : totalColl.sub(_collChange);
      // totalDebt = _isDebtIncrease ? totalDebt.add(_debtChange) : totalDebt.sub(_debtChange);

      // uint newTCR = LiquityMath._computeCR(totalColl, totalDebt, _price);
      // return newTCR;
      return 1;
    }
  }
}
