use starknet::ContractAddress;

#[starknet::interface]
pub trait ILockupContractFactory {
  #[derive(starknet::Event, Drop)]
  pub struct MartenTokenAddressSet {
    pub marten_token_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct LockupContractDeployedThroughFactory {
    pub lockup_contract_address: ContractAddress,
    pub beneficiary: ContractAddress,
    pub unlockTime: u256,
    pub deployer: ContractAddress,
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    MartenTokenAddressSet: MartenTokenAddressSet,
      LockupContractDeployedThroughFactory: LockupContractDeployedThroughFactory
  }

  fn set_marten_token_address(marten_token_address: ContractAddress);

  fn deploy_lockup_contract(beneficiary: ContractAddress, unlockTime: u256);

  fn is_registered_lockup(addr: ContractAddress) -> bool;
}
