use starknet::ContractAddress;

use snforge_std_deprecated::{declare, ContractClassTrait, DeclareResultTrait};

use hello_starknet::IHelloStarknetSafeDispatcher;
use hello_starknet::IHelloStarknetSafeDispatcherTrait;
use hello_starknet::IHelloStarknetDispatcher;
use hello_starknet::IHelloStarknetDispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

pub fn factorial(a: felt252) -> felt252 {
    if a == 1 || a == 0 {
        return 1;
    }
    return a * factorial(a - 1);
}
#[test]
fn test_factorial() {
    assert_eq!(factorial(2), 2, "bad factorial");
    assert_eq!(factorial(3), 6, "bad factorial");
    assert_eq!(factorial(4), 24, "bad factorial");
    assert_eq!(factorial(10), 3628800, "bad factorial");
    assert_eq!(factorial(2000000), 0x4d6e41de886ac83938da3456ccf1481182687989ead34d9d35236f0864575a0, "bad factorial")
}
