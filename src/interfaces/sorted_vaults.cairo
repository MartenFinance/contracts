use starknet::ContractAddress;

#[starknet::interface]
pub trait ISortedVaults<TContractState> {
  fn set_params(ref self: TContractState, size: u256, trove_manager_address: ContractAddress, borrower_operations_address: ContractAddress);

  fn insert(ref self: TContractState, id: ContractAddress, icr: u256, prev_id: ContractAddress, next_id: ContractAddress);

  fn remove(ref self: TContractState, id: ContractAddress);

  fn re_insert(ref self: TContractState, id: ContractAddress, new_icr: u256, prev_id: ContractAddress, next_id: ContractAddress);

  fn contains(self: @TContractState, id: ContractAddress) -> bool;

  fn is_full(self: @TContractState) -> bool;

  fn is_empty(self: @TContractState) -> bool;

  fn get_size(self: @TContractState) -> u256;

  fn get_max_size(self: @TContractState) -> u256;

  fn get_first(self: @TContractState) -> ContractAddress;

  fn get_last(self: @TContractState) -> ContractAddress;

  fn get_next(self: @TContractState, id: ContractAddress) -> ContractAddress;

  fn get_prev(self: @TContractState, id: ContractAddress) -> ContractAddress;

  fn valid_insert_position(self: @TContractState, icr: u256, prev_id: ContractAddress, next_id: ContractAddress) -> bool;

  fn find_insert_position(self: @TContractState, icr: u256, prev_id: ContractAddress, next_id: ContractAddress) -> (ContractAddress, ContractAddress);

  // #[derive(starknet::Event, Drop)]
  // pub struct SortedVaultsAddressChanged {
  //   pub sorted_doublyLL_address: ContractAddress
  // }

  // #[derive(starknet::Event, Drop)]
  // pub struct BorrowerOperationsAddressChanged {
  //   pub borrower_operations_address: ContractAddress
  // };

  // #[derive(starknet::Event, Drop)]
  // pub NodeAdded {
  //   pub id: ContractAddress,
  //   pub nicr: u256
  // };

  // #[derive(starknet::Event, Drop)]
  // pub NodeRemoved {
  //   pub id: ContractAddress
  // }

  // #[event]
  // #[derive(starknet::Event, Drop)]
  // enum Event {
  //   SortedVaultsAddressChanged: SortedVaultsAddressChanged,
  //   BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
  //   NodeAdded: NodeAdded,
  //   NodeRemoved: NodeRemoved,
  // }
}
