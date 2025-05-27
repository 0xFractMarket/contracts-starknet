use starknet::ContractAddress;
use starknet::get_caller_address;

#[starknet::interface]
trait IPropertyToken<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, id: u256, amount: u256);
    fn balance_of(self: @TContractState, account: ContractAddress, id: u256) -> u256;
}

#[starknet::contract]
mod PropertyToken {
    use super::IPropertyToken;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        // Mapping from token ID to account balances
        balances: LegacyMap::<(ContractAddress, u256), u256>,
        // Mapping from token ID to total supply
        total_supply: LegacyMap::<u256, u256>,
        // Owner address
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TransferSingle: TransferSingle,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferSingle {
        operator: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        id: u256,
        value: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
    }

    #[external(v0)]
    impl IPropertyTokenImpl of IPropertyToken<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, id: u256, amount: u256) {
            // Only owner can mint
            assert(self.owner.read() == get_caller_address(), 'Caller is not the owner');
            
            // Update the balance
            let current_balance = self.balances.read((to, id));
            self.balances.write((to, id), current_balance + amount);
            
            // Update total supply
            let current_supply = self.total_supply.read(id);
            self.total_supply.write(id, current_supply + amount);

            // Emit transfer event
            self.emit(TransferSingle { 
                operator: get_caller_address(),
                from: 0.try_into().unwrap(),
                to: to,
                id: id,
                value: amount
            });
        }

        fn balance_of(self: @ContractState, account: ContractAddress, id: u256) -> u256 {
            self.balances.read((account, id))
        }
    }
} 