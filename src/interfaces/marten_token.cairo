use starknet::ContractAddress;

#[starknet::interface]
pub trait IMARTENToken<TContractState> {
  fn send_to_marten_staking(ref self: TContractState, sender: ContractAddress, amount: u256) external;
  fn get_deployment_start_time(self: @TContractState) -> u256;
  fn get_lp_rewards_entitlement(self: @TContractState) -> u256;

  // #[derive(starknet::Event, Drop)]
  // pub struct CommunityIssuanceAddressSet {
  //   pub community_issuance_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct MARTENStakingAddressSet {
  //   pub marten_staking_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct LockupContractFactoryAddressSet {
  //   pub lockup_contract_factory_address: ContractAddress
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   CommunityIssuanceAddressSet: CommunityIssuanceAddressSet,
  //   MARTENStakingAddressSet: MARTENStakingAddressSet,
  //   LockupContractFactoryAddressSet: LockupContractFactoryAddressSet,
  // }
}
