#[starknet::contract]
mod Market {
    use core::byte_array::ByteArray;
    use core::num::traits::zero::Zero;
    use openzeppelin_token::erc20::{
        DefaultConfig, ERC20ABIDispatcher, ERC20ABIDispatcherTrait, ERC20Component,
        ERC20HooksEmptyImpl,
    };
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use uf::events;
    use uf::interface::{BorrowerDetails, BorrowerReqDetails, IAdmin, IBorrower, ILender};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    const FIXED_PRECISION: u256 = 1000000000000000000;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        key_cnt: u8,
        admin: ContractAddress,
        owner: ContractAddress,
        key_to_borrower_queue: Map<u8, BorrowerReqDetails>,
        key_to_borrower_details: Map<u8, BorrowerDetails>,
        total_deposit: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        BorrowerReqEvent: events::BorrowerReqEvent,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, admin: ContractAddress) {
        let name: ByteArray = "UFBTC";
        let symbol: ByteArray = "UFBTC";
        self.erc20.initializer(name, symbol);
        self.admin.write(admin);
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl AdminImpl of IAdmin<ContractState> {
        fn register_borrower(ref self: ContractState, details: BorrowerReqDetails) -> u8 {
            self.validate_borrower_req_details(details);
            let key = self.key_cnt.read();
            self.key_to_borrower_queue.write(key, details);
            self.key_cnt.write(self.key_cnt.read() + 1);
            self.emit(events::BorrowerReqEvent { id: key });
            key
        }
        fn complete_borrower_onboarding(ref self: ContractState, key: u8) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'E_NOT_ADMIN');
            let borrower_details: BorrowerReqDetails = self.key_to_borrower_queue.read(key);
            self.validate_borrower_req_details(borrower_details);
            self
                .key_to_borrower_details
                .write(
                    key,
                    BorrowerDetails {
                        borrower_entity: borrower_details.borrower_entity,
                        kyc: true,
                        asset: borrower_details.asset,
                        collateral: borrower_details.collateral,
                        borrower: borrower_details.borrower,
                        cap: borrower_details.cap,
                        verified_by_platform: true,
                        started_from: get_block_timestamp(),
                    },
                )
        }
        fn add_admin(ref self: ContractState, admin: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'E_NOT_OWNER');
            self.admin.write(admin);
        }
    }

    #[abi(embed_v0)]
    impl LenderImpl of ILender<ContractState> {
        fn deposit(ref self: ContractState, key: u8, amount: u256) {
            assert(amount.is_non_zero(), 'E_ZERO_AMOUNT');
            assert(key.is_non_zero(), 'E_ZERO_KEY');
            let caller = get_caller_address();
            let market_details = self._get_borrower_details(key);
            let token_dispatcher = self.get_erc20_dispatcher(market_details.asset);
            token_dispatcher.transferFrom(caller, get_contract_address(), amount);
            self.total_deposit.write(self.total_deposit.read() + amount);
            self._mint(caller, amount);
        }
        fn withdraw(ref self: ContractState, key: u8) {
            assert(key.is_non_zero(), 'E_ZERO_KEY');
            let caller = get_caller_address();
            let balance = self._balance_of(caller);
            let amount = self.calculate_withdraw_amount(balance);
            self.total_deposit.write(self.total_deposit.read() - amount);
            self._burn(caller, balance);
            let market_details = self._get_borrower_details(key);
            let token_dispatcher = self.get_erc20_dispatcher(market_details.asset);
            token_dispatcher.transfer(caller, amount);
        }
    }

    #[abi(embed_v0)]
    impl BorrowerImpl of IBorrower<ContractState> {
        fn repay(ref self: ContractState, key: u8, amount: u256) {
            assert(amount.is_non_zero(), 'E_ZERO_AMOUNT');
            let caller = get_caller_address();
            let borrower_details = self._get_borrower_details(key);
            assert(caller == borrower_details.borrower, 'E_NOT_BORROWER');

            let token_dispatcher = self.get_erc20_dispatcher(borrower_details.asset);
            token_dispatcher.transferFrom(caller, get_contract_address(), amount);
        }
        fn claim_collateral(ref self: ContractState, key: u8) {
            assert(key.is_non_zero(), 'E_ZERO_KEY');
            let caller = get_caller_address();
            let borrower_details = self._get_borrower_details(key);
            assert(caller == borrower_details.borrower, 'E_NOT_BORROWER');

            let token_dispatcher = self.get_erc20_dispatcher(borrower_details.collateral);
            let collateral_balance = token_dispatcher.balanceOf(get_contract_address());
            token_dispatcher.transfer(caller, collateral_balance);
        }

        fn claim_assets(ref self: ContractState, key: u8, receiver: ContractAddress, amount: u256) {
            assert(key.is_non_zero(), 'E_ZERO_KEY');
            assert(receiver.is_non_zero(), 'E_RECEIVER_ZERO');
            assert(amount.is_non_zero(), 'E_AMOUNT_ZERO');
            let caller = get_caller_address();
            let borrower_details = self._get_borrower_details(key);
            assert(caller == borrower_details.borrower, 'E_NOT_BORROWER');

            let token_dispatcher = self.get_erc20_dispatcher(borrower_details.asset);
            token_dispatcher.transfer(receiver, amount);
        }
        fn get_borrower_details(self: @ContractState, key: u8) -> BorrowerDetails {
            self.key_to_borrower_details.read(key)
        }
    }

    #[generate_trait]
    impl MarketInternal of MarketInternalMethods {
        fn validate_borrower_req_details(self: @ContractState, details: BorrowerReqDetails) {
            assert(details.borrower_entity.is_non_zero(), 'E_ZERO_BORROWER_ENTITY');
            assert(details.asset.is_non_zero(), 'E_ZERO_ASSET_ADDR');
            assert(details.borrower.is_non_zero(), 'E_ZERO_BORROWER_ADDR');
            assert(details.collateral.is_non_zero(), 'E_ZERO_COLLATERAL_ADDR');
            assert(details.cap.is_non_zero(), 'E_ZERO_CAP_ADDR');
        }

        fn calculate_withdraw_amount(self: @ContractState, balance: u256) -> u256 {
            assert(balance.is_non_zero(), 'E_ZERO_WITHDRAW_BALANCE');
            let reward_mul = self.calculate_reward_mul();
            let amount = balance * reward_mul / FIXED_PRECISION;
            amount
        }

        fn calculate_reward_mul(self: @ContractState) -> u256 {
            let amount_repayed: u256 = 0_u256; //TODO: Would be read from repayment struct
            let interest: u256 = amount_repayed - self.total_deposit.read();
            let reward_mul = interest * FIXED_PRECISION / self.total_deposit.read();
            reward_mul
        }

        fn get_erc20_dispatcher(
            ref self: ContractState, addr: ContractAddress,
        ) -> ERC20ABIDispatcher {
            ERC20ABIDispatcher { contract_address: addr }
        }

        fn _get_borrower_details(self: @ContractState, key: u8) -> BorrowerDetails {
            self.key_to_borrower_details.read(key)
        }

        fn _mint(ref self: ContractState, receiver: ContractAddress, amount: u256) {
            self.erc20.mint(receiver, amount);
        }

        fn _burn(ref self: ContractState, owner: ContractAddress, amount: u256) {
            self.erc20.burn(owner, amount);
        }

        fn _balance_of(ref self: ContractState, addr: ContractAddress) -> u256 {
            self.erc20.balanceOf(addr)
        }
    }
}
