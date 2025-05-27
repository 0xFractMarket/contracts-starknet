use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::storage::Map;

#[starknet::interface]
trait IPropertyToken<TContractState> {
    fn mint_property(ref self: TContractState, property_id: u256, amount: u256);
    fn balance_of(self: @TContractState, account: ContractAddress, id: u256) -> u256;
    fn get_property_price(self: @TContractState, property_id: u256) -> u256;
    fn set_property_price(ref self: TContractState, property_id: u256, price: u256);
    fn withdraw_funds(ref self: TContractState);
    fn transfer(ref self: TContractState, to: ContractAddress, property_id: u256, amount: u256);
    fn burn(ref self: TContractState, property_id: u256, amount: u256);
    fn set_property_name(ref self: TContractState, property_id: u256, name: felt252);
    fn get_property_name(self: @TContractState, property_id: u256) -> felt252;
    fn set_property_description(ref self: TContractState, property_id: u256, description: felt252);
    fn get_property_description(self: @TContractState, property_id: u256) -> felt252;
    fn set_property_location(ref self: TContractState, property_id: u256, location: felt252);
    fn get_property_location(self: @TContractState, property_id: u256) -> felt252;
    fn set_property_size(ref self: TContractState, property_id: u256, size: u256);
    fn get_property_size(self: @TContractState, property_id: u256) -> u256;
}

#[starknet::contract]
mod PropertyToken {
    use super::IPropertyToken;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::Map;

    #[storage]
    struct Storage {
        // Mapping from token ID to account balances
        balances: Map::<(ContractAddress, u256), u256>,
        // Mapping from token ID to total supply
        total_supply: Map::<u256, u256>,
        // Mapping from property ID to its price in STRK
        property_prices: Map::<u256, u256>,
        // Property metadata
        property_names: Map::<u256, felt252>,
        property_descriptions: Map::<u256, felt252>,
        property_locations: Map::<u256, felt252>,
        property_sizes: Map::<u256, u256>,
        // Owner address
        owner: ContractAddress,
        // Contract balance
        contract_balance: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TransferSingle: TransferSingle,
        PropertyPriceSet: PropertyPriceSet,
        FundsWithdrawn: FundsWithdrawn,
        Burn: Burn,
        PropertyMetadataUpdated: PropertyMetadataUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferSingle {
        operator: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        id: u256,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PropertyPriceSet {
        property_id: u256,
        price: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct FundsWithdrawn {
        amount: u256,
        to: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct Burn {
        operator: ContractAddress,
        from: ContractAddress,
        id: u256,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PropertyMetadataUpdated {
        property_id: u256,
        field: felt252,
        value: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
    }

    #[external(v0)]
    impl IPropertyTokenImpl of IPropertyToken<ContractState> {
        fn mint_property(ref self: ContractState, property_id: u256, amount: u256) {
            // Get the price for this property
            let price = self.property_prices.read(property_id);
            assert(price > 0, 'Property price not set');
            
            // Calculate total cost
            let total_cost = price * amount;
            
            // Update contract balance
            let current_balance = self.contract_balance.read();
            self.contract_balance.write(current_balance + total_cost);
            
            // Update the balance
            let caller = get_caller_address();
            let current_balance = self.balances.read((caller, property_id));
            self.balances.write((caller, property_id), current_balance + amount);
            
            // Update total supply
            let current_supply = self.total_supply.read(property_id);
            self.total_supply.write(property_id, current_supply + amount);

            // Emit transfer event
            self.emit(TransferSingle { 
                operator: caller,
                from: 0.try_into().unwrap(),
                to: caller,
                id: property_id,
                value: amount
            });
        }

        fn balance_of(self: @ContractState, account: ContractAddress, id: u256) -> u256 {
            self.balances.read((account, id))
        }

        fn get_property_price(self: @ContractState, property_id: u256) -> u256 {
            self.property_prices.read(property_id)
        }

        fn set_property_price(ref self: ContractState, property_id: u256, price: u256) {
            // Only owner can set prices
            assert(self.owner.read() == get_caller_address(), 'Caller is not the owner');
            self.property_prices.write(property_id, price);
            
            // Emit event
            self.emit(PropertyPriceSet { 
                property_id: property_id,
                price: price
            });
        }

        fn withdraw_funds(ref self: ContractState) {
            // Only owner can withdraw
            assert(self.owner.read() == get_caller_address(), 'Caller is not the owner');
            
            let amount = self.contract_balance.read();
            assert(amount > 0, 'No funds to withdraw');
            
            // Reset contract balance
            self.contract_balance.write(0);
            
            // Emit event
            self.emit(FundsWithdrawn { 
                amount: amount,
                to: self.owner.read()
            });
        }

        fn transfer(ref self: ContractState, to: ContractAddress, property_id: u256, amount: u256) {
            let from = get_caller_address();
            
            // Check if sender has enough tokens
            let from_balance = self.balances.read((from, property_id));
            assert(from_balance >= amount, 'Insufficient token balance');
            
            // Update sender's balance
            self.balances.write((from, property_id), from_balance - amount);
            
            // Update recipient's balance
            let to_balance = self.balances.read((to, property_id));
            self.balances.write((to, property_id), to_balance + amount);
            
            // Emit transfer event
            self.emit(TransferSingle { 
                operator: from,
                from: from,
                to: to,
                id: property_id,
                value: amount
            });
        }

        fn burn(ref self: ContractState, property_id: u256, amount: u256) {
            let from = get_caller_address();
            
            // Check if sender has enough tokens
            let from_balance = self.balances.read((from, property_id));
            assert(from_balance >= amount, 'Insufficient token balance');
            
            // Update sender's balance
            self.balances.write((from, property_id), from_balance - amount);
            
            // Update total supply
            let current_supply = self.total_supply.read(property_id);
            self.total_supply.write(property_id, current_supply - amount);
            
            // Emit burn event
            self.emit(Burn { 
                operator: from,
                from: from,
                id: property_id,
                value: amount
            });
        }

        fn set_property_name(ref self: ContractState, property_id: u256, name: felt252) {
            // Only owner can set metadata
            assert(self.owner.read() == get_caller_address(), 'Caller is not the owner');
            
            // Store name
            self.property_names.write(property_id, name);
            
            // Emit event
            self.emit(PropertyMetadataUpdated { 
                property_id: property_id,
                field: 'name',
                value: name
            });
        }

        fn get_property_name(self: @ContractState, property_id: u256) -> felt252 {
            self.property_names.read(property_id)
        }

        fn set_property_description(ref self: ContractState, property_id: u256, description: felt252) {
            // Only owner can set metadata
            assert(self.owner.read() == get_caller_address(), 'Caller is not the owner');
            
            // Store description
            self.property_descriptions.write(property_id, description);
            
            // Emit event
            self.emit(PropertyMetadataUpdated { 
                property_id: property_id,
                field: 'description',
                value: description
            });
        }

        fn get_property_description(self: @ContractState, property_id: u256) -> felt252 {
            self.property_descriptions.read(property_id)
        }

        fn set_property_location(ref self: ContractState, property_id: u256, location: felt252) {
            // Only owner can set metadata
            assert(self.owner.read() == get_caller_address(), 'Caller is not the owner');
            
            // Store location
            self.property_locations.write(property_id, location);
            
            // Emit event
            self.emit(PropertyMetadataUpdated { 
                property_id: property_id,
                field: 'location',
                value: location
            });
        }

        fn get_property_location(self: @ContractState, property_id: u256) -> felt252 {
            self.property_locations.read(property_id)
        }

        fn set_property_size(ref self: ContractState, property_id: u256, size: u256) {
            // Only owner can set metadata
            assert(self.owner.read() == get_caller_address(), 'Caller is not the owner');
            
            // Store size
            self.property_sizes.write(property_id, size);
            
            // Emit event
            self.emit(PropertyMetadataUpdated { 
                property_id: property_id,
                field: 'size',
                value: size.try_into().unwrap()
            });
        }

        fn get_property_size(self: @ContractState, property_id: u256) -> u256 {
            self.property_sizes.read(property_id)
        }
    }
} 