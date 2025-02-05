use starknet::ContractAddress;

#[starknet::interface]
pub trait IHintHelpers<TContractState> {
  fn set_addresses(
    ref self: TContractState,
    marten_base_address: ContractAddress,
    marten_math_address: ContractAddress,
    sorted_vaults_address: ContractAddress,
    vault_manager_address: ContractAddress,
  );

  fn get_redemption_hints(self: @TContractState, usdm_amount: u256, price: u256, max_iterations: u256) -> (ContractAddress, u256, u256);

  fn get_approx_hint(self: @TContractState, cr: u256, num_trials: u256, input_random_seed: u256) -> (ContractAddress, u256, u256);

  fn compute_nominal_cr(self: @TContractState, coll: u256, debt: u256) -> u256;

  fn compute_cr(self: @TContractState, coll: u256, debt: u256, price: u256) -> u256;
}
