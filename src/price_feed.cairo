#[starknet::contract]
pub mod PriceFeed {
  use starknet::ContractAddress;
  use marten::interfaces::price_feed::IPriceFeed;
  use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
  use pragma_lib::types::{DataType, PragmaPricesResponse};

  const ETH_USD: felt252 = 19514442401534788;

  #[storage]
  struct Storage {
    pragma_contract: ContractAddress,
  }

  #[event]
  #[derive(starknet::Event, Drop)]
  enum Event {
    LastGoodPriceUpdated: LastGoodPriceUpdated,
  }

  #[derive(starknet::Event, Drop)]
  pub struct LastGoodPriceUpdated {
    pub last_good_price: u256
  }

  #[constructor]
  fn constructor(ref self: ContractState, pragma_address: ContractAddress) {
    self.pragma_contract.write(pragma_address)
  }

  #[abi(embed_v0)]
  impl PriceFeedImpl of IPriceFeed<ContractState> {
    fn fetch_price(self: @ContractState) -> u256 {
      let oracle_dispatcher = IPragmaABIDispatcher {
        contract_address: self.pragma_contract.read()
      };

      let output: PragmaPricesResponse = oracle_dispatcher.get_data_median(DataType::SpotEntry(ETH_USD));
      let price: u256 = output.price.into();

      price
    }
  }
}
