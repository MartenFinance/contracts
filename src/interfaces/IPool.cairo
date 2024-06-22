use starknet::{ContractAddress};

#[starknet::interface]
pub trait IPool {
    #[derive(starknet::Event, Drop)]
    pub struct ETHBalanceUpdated {
      pub new_balance: u256
    }

    #[derive(starknet::Event, Drop)]
    pub struct USDMBalanceUpdated {
      pub new_balance: u256
    }

    #[derive(starknet::Event, Drop)]
    pub struct ActivePoolAddressChanged {
      pub new_active_pool_address: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    pub struct DefaultPoolAddressChanged {
      pub new_default_pool_address: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    pub struct StabilityPoolAddressChanged {
      pub new_stability_pool_address: ContractAddress
    }

    #[derive(starknet::Event, Drop)]
    pub struct EtherSent {
      pub to: ContractAddress,
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
