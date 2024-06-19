use starknet::{ContractAddress}

#[starknet::interface]
pub trait IPool {
    #[derive(starknet::Event, Drop)]
    pub struct ETHBalanceUpdated {
      pub newBalance: u256
    }

    #[derive(starknet::Event, Drop)]
    pub struct USDMBalanceUpdated {
      pub newBalance: u256
    }

    #[derive(starknet::Event, Drop)]
    pub struct ActivePoolAddressChanged {
      pub newActivePoolAddress: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    pub struct DefaultPoolAddressChanged {
      pub newDefaultPoolAddress: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    pub struct StabilityPoolAddressChanged {
      pub newStabilityPoolAddress: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    pub struct EtherSent {
      pub to: ContractAddress
      pub amount: u256
    }

    #[event]
    #[derive(starknet::Event, Drop)]
    enum Event {
        ETHBalanceUpdated: ETHBalanceUpdated,
        USDMBalanceUpdated: USDMBalanceUpdated,
        ActivePoolAddressChanged: ActivePoolAddressChanged,
        DefaultPoolAddressChanged: DefaultPoolAddressChanged,
        StabilityPoolAddressChanged: StabilityPoolAddressChanged,
        EtherSent: EtherSent,
    }

    fn get_eth() -> u256;

    fn get_usdm_debt() -> u256;

    fn increase_usdm_debt(amount: u256) -> u256;

    fn decrease_usdm_debt(amount: u256) -> u256;
}
