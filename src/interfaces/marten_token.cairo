use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::IERC20;

#[starknet::interface]
#[abi(embed_v0)]
impl IMARTENToken of IERC20<ContractState> {
  #[derive(starknet::Event, Drop)]
  pub struct CommunityIssuanceAddressSet {
    pub community_issuance_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct MARTENStakingAddressSet {
    pub marten_staking_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct LockupContractFactoryAddressSet {
    pub lockup_contract_factory_address: ContractAddress
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    CommunityIssuanceAddressSet: CommunityIssuanceAddressSet,
    MARTENStakingAddressSet: MARTENStakingAddressSet,
    LockupContractFactoryAddressSet: LockupContractFactoryAddressSet,
  }

  fn send_to_marten_staking(self: @ContractState, sender: ContractAddress, amount: u256) external;

  fn get_deployment_start_time(self: @ContractState) -> u256;

  fn get_lp_rewards_entitlement(self: @ContractState) -> u256;
}
