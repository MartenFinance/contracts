use starknet::ContractAddress;

#[starknet::interface]
pub trait IBorrowerOperations<TContractState> {
  fn set_addresses(
    ref self: TContractState,
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
  );

  fn open_vault(ref self: TContractState, max_fee_percentage: u256, eth_amount: u256, usdm_amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn add_coll(ref self: TContractState, eth_amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn move_eth_gain_to_vault(ref self: TContractState, user: ContractAddress, eth_amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn withdraw_coll(ref self: TContractState, coll_withdrawal: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn withdraw_usdm(ref self: TContractState, max_fee_percentage: u256, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn repay_usdm(ref self: TContractState, amount: u256, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn close_vault(ref self: TContractState);

  fn adjust_vault(ref self: TContractState, max_fee: u256, coll_withdrawal: u256, eth_amount: u256, debt_change: u256, is_debt_increase: bool, upper_hint: ContractAddress, lower_hint: ContractAddress);

  fn claim_collateral(ref self: TContractState);
}
