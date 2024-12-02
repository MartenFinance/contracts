use starknet::ContractAddress;

#[starknet::interface]
interface ISortedTroves {
  #[derive(starknet::Event, Drop)]
  pub struct SortedTrovesAddressChanged {
    pub sorted_doublyLL_address: ContractAddress
  }

  #[derive(starknet::Event, Drop)]
  pub struct BorrowerOperationsAddressChanged {
    pub borrower_operations_address: ContractAddress
  };

  #[derive(starknet::Event, Drop)]
  pub NodeAdded {
    pub id: ContractAddress,
    pub nicr: u256
  };

  #[derive(starknet::Event, Drop)]
  pub NodeRemoved {
    pub id: ContractAddress
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    SortedTrovesAddressChanged: SortedTrovesAddressChanged,
    BorrowerOperationsAddressChanged: BorrowerOperationsAddressChanged,
    NodeAdded: NodeAdded,
    NodeRemoved: NodeRemoved,
  }

  fn set_params(size: u256, trove_manager_address: ContractAddress, borrower_operations_address: ContractAddress);

  fn insert(id: ContractAddress, icr: u256, prev_id: ContractAddress, next_id: ContractAddress);

  fn remove(id: ContractAddress);

  fn re_insert(id: ContractAddress, new_icr: ContractAddress, prev_id: ContractAddress, next_id: ContractAddress);

  fn contains(id: ContractAddress) -> bool;

  fn is_full() -> bool;

  fn is_empty() -> bool;

  fn get_size() -> u256;

  fn get_max_size() -> u256;

  fn get_first() -> ContractAddress;

  fn get_last() -> ContractAddress;

  fn get_next(id: ContractAddress) -> ContractAddress;

  fn get_prev(id: ContractAddress) -> ContractAddress;

  fn valid_insert_position(icr: u256, prev_id: ContractAddress, next_id: ContractAddress) -> bool;

  fn find_insert_position(icr: u256, prev_id: ContractAddress, next_id: ContractAddress) -> (next_id: ContractAddress, prev_id: ContractAddress);
}
