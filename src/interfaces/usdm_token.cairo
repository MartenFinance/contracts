use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::IERC20;

#[starknet::interface]
#[abi(embed_v0)]
#[abi(embed_v0)]
impl IUSDMToken of IERC20<ContractState> {
  #[derive(starknet::Event, Drop)]
  pub struct VaultManagerAddressChanged {
    pub vault_manager_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct StabilityPoolAddressChanged {
    pub new_stability_pool_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct BorrowerOperationsAddressChanged {
    pub new_borrower_operations_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct USDMTokenBalanceUpdated {
    pub user: ContractAddress,
    pub amount: u256
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    VaultManagerAddressChanged: VaultManagerAddressChanged,
    StabilityPoolAddressChanged: StabilityPoolAddressChanged,
    BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
    USDMTokenBalanceUpdated: USDMTokenBalanceUpdated,
  }

  fn mint(account: ContractAddress, amount: u256);

  fn burn(account: ContractAddress, amount: u256);

  fn send_to_pool(sender: ContractAddress, pool_address: ContractAddress, amount: u256);

  fn return_from_pool(pool_address: ContractAddress, user: ContractAddress, amount: u256);
}
