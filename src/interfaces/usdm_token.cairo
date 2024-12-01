use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::IERC20;

#[starknet::interface]
impl IUSDMToken of IERC20<TContractState> {
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

  fn mint(self: @TContractState, account: ContractAddress, amount: u256);

  fn burn(self: @TContractState, account: ContractAddress, amount: u256);

  fn send_to_pool(self: @TContractState, ender: ContractAddress, pool_address: ContractAddress, amount: u256);

  fn return_from_pool(self: @TContractState, pool_address: ContractAddress, user: ContractAddress, amount: u256);
}
