use starknet::ContractAddress;

#[derive(Drop, Serde, Copy, starknet::Store)]
pub struct CombinedVaultData {
  pub owner: ContractAddress,
  pub debt: u256,
  pub coll: u256,
  pub stake: u256,
  pub snapshot_eth: u256,
  pub snapshot_usdm_debt: u256,
}

#[starknet::interface]
pub trait IMultiVaultGetter<TContractState> {
  fn get_multiple_sorted_vaults(self: @TContractState, start_index: felt252, count: u256) -> Array<CombinedVaultData>;
}

#[starknet::contract]
pub mod MultiVaultGetter {
  use core::num::traits::Zero;
  use starknet::ContractAddress;
  use super::CombinedVaultData;
  use marten::interfaces::sorted_vaults::{ISortedVaultsDispatcher, ISortedVaultsDispatcherTrait};

  #[storage]
  struct Storage {
    pub vault_manager_address: ContractAddress,
    pub sorted_vaults_address: ContractAddress,
  }

  #[constructor]
  fn constructor(ref self: ContractState, vault_manager_address: ContractAddress, sorted_vaults_address: ContractAddress) {
    assert(!vault_manager_address.is_zero(), 'MVG:VM_ZERO');
    assert(!sorted_vaults_address.is_zero(), 'MVG_SV_ZERO');

    self.vault_manager_address.write(vault_manager_address);
    self.sorted_vaults_address.write(sorted_vaults_address);
  }

  // #[abi(embed_v0)]
  // impl MultiVaultGetterImpl of IMultiVaultGetter<ContractState> {
  //   fn get_multiple_sorted_vaults(self: @ContractState, start_index: felt252, count: u256) -> Array<CombinedVaultData> {
  //     let mut _start_index = 0;
  //     let mut descend = false;

  //     if (start_index >= 0) {
  //       _start_index = start_index.into();
  //     }

  //     return ArrayTrait::new(0);
  //   }
  // }

  #[generate_trait]
  impl InternalFunctions of InternalFuctionsTrait {
    fn get_multiple_sorted_vaults_from_head(self: @ContractState, start_index: u256, count: u256) -> Array<CombinedVaultData> {
      let sorted_vaults_contract: ISortedVaultsDispatcher = ISortedVaultsDispatcher { contract_address: self.sorted_vaults_address.read() };
      let mut current_vault_owner = sorted_vaults_contract.get_first();


      let mut i: u256 = 0;
      loop {
        if (i == count - 1) {
          break;
        };

        current_vault_owner = sorted_vaults_contract.get_next(current_vault_owner);
      };

      let vaults = ArrayTrait::<CombinedVaultData>::new();

      let mut j: u256 = 0;
      loop {
        if (j == count - 1) {
          break;
        };

        // let vault = vault_manager_contract.
      };

      return vaults;
    }
    // function _getMultipleSortedTrovesFromHead(uint _startIdx, uint _count)
    //     internal view returns (CombinedTroveData[] memory _troves)
    // {
    //     address currentTroveowner = sortedTroves.getFirst();

    //     for (uint idx = 0; idx < _startIdx; ++idx) {
    //         currentTroveowner = sortedTroves.getNext(currentTroveowner);
    //     }

    //     _troves = new CombinedTroveData[](_count);

    //     for (uint idx = 0; idx < _count; ++idx) {
    //         _troves[idx].owner = currentTroveowner;
    //         (
    //             _troves[idx].debt,
    //             _troves[idx].coll,
    //             _troves[idx].stake,
    //             /* status */,
    //             /* arrayIndex */
    //         ) = troveManager.Troves(currentTroveowner);
    //         (
    //             _troves[idx].snapshotETH,
    //             _troves[idx].snapshotLUSDDebt
    //         ) = troveManager.rewardSnapshots(currentTroveowner);

    //         currentTroveowner = sortedTroves.getNext(currentTroveowner);
    //     }
    // }

    // function _getMultipleSortedTrovesFromTail(uint _startIdx, uint _count)
    //     internal view returns (CombinedTroveData[] memory _troves)
    // {
    //     address currentTroveowner = sortedTroves.getLast();

    //     for (uint idx = 0; idx < _startIdx; ++idx) {
    //         currentTroveowner = sortedTroves.getPrev(currentTroveowner);
    //     }

    //     _troves = new CombinedTroveData[](_count);

    //     for (uint idx = 0; idx < _count; ++idx) {
    //         _troves[idx].owner = currentTroveowner;
    //         (
    //             _troves[idx].debt,
    //             _troves[idx].coll,
    //             _troves[idx].stake,
    //             /* status */,
    //             /* arrayIndex */
    //         ) = troveManager.Troves(currentTroveowner);
    //         (
    //             _troves[idx].snapshotETH,
    //             _troves[idx].snapshotLUSDDebt
    //         ) = troveManager.rewardSnapshots(currentTroveowner);

    //         currentTroveowner = sortedTroves.getPrev(currentTroveowner);
    //     }
    // }
  }
}
