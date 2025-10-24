use starknet::ContractAddress;

#[derive(Debug, Drop, PartialEq, starknet::Event)]
pub struct BorrowerReqEvent {
    #[key]
    pub id: u8,
}

