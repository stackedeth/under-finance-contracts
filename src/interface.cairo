use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store, PartialEq, Debug)]
pub struct BorrowerReqDetails {
    pub borrower_entity: felt252,
    pub asset: ContractAddress,
    pub collateral: ContractAddress,
    pub borrower: ContractAddress,
    pub cap: u256,
}

#[derive(Copy, Drop, Serde, starknet::Store, PartialEq, Debug)]
pub struct BorrowerDetails {
    pub borrower_entity: felt252,
    pub kyc: bool,
    pub asset: ContractAddress,
    pub collateral: ContractAddress,
    pub borrower: ContractAddress,
    pub cap: u256,
    pub verified_by_platform: bool,
    pub started_from: u64,
}

#[starknet::interface]
pub trait ILender<TContractState> {
    fn deposit(ref self: TContractState, key: u8, amount: u256);
    fn withdraw(ref self: TContractState, key: u8);
}

#[starknet::interface]
pub trait IBorrower<TContractState> {
    fn repay(ref self: TContractState, key: u8, amount: u256);
    fn claim_collateral(ref self: TContractState, key: u8);
    fn get_borrower_details(self: @TContractState, key: u8) -> BorrowerDetails;
    fn claim_assets(ref self: TContractState, key: u8, receiver: ContractAddress, amount: u256);
}


#[starknet::interface]
pub trait IAdmin<TContractState> {
    fn register_borrower(ref self: TContractState, details: BorrowerReqDetails) -> u8;
    fn complete_borrower_onboarding(ref self: TContractState, key: u8);
    fn add_admin(ref self: TContractState, admin: ContractAddress);
}
