use core::dict::Felt252Dict;

fn main() -> felt252 {
    factorial(1, 1)
}

fn factorial(value: felt252, n: felt252) -> felt252 {
    if (n == 1) {
        value
    } else {
        factorial(value * n, n - 1)
    }
}

fn init_dict(length: u64) -> Felt252Dict<felt252> {
    let mut balances: Felt252Dict<felt252> = Default::default();

    for i in 0..length {
        let x: felt252 = i.into();
        balances.insert(x, x);
    };

    return balances;
}

fn fib(a: felt252, b: felt252, n: felt252) -> felt252 {
    match n {
        0 => a,
        _ => fib(b, a + b, n - 1),
    }
}

fn search(array: @Array<felt252>, number: felt252) -> u32 {
    let mut index = 0;

    while index < array.len() {
        if *array[index] == number {
            break;
        }

        index += 1;
    };

    return index;
}

fn init_array(length: u32) -> Array<felt252> {
    let mut array = ArrayTrait::new();
    for i in 0..length {
        array.append(i.into());
    };

    return array;
}

#[cfg(test)]
mod tests {
    use super::{factorial, init_dict, fib, init_array, search};

    #[test]
    fn test_factorial() {
        assert_eq!(factorial(1, 2), 2, "invalid result");
        assert_eq!(factorial(1, 3), 6, "invalid result");
        assert_eq!(factorial(1, 4), 24, "invalid result");
        assert_eq!(factorial(1, 10), 3628800, "invalid result");
        assert_eq!(factorial(1, 2000000), 0x4d6e41de886ac83938da3456ccf1481182687989ead34d9d35236f0864575a0, "invalid result");
    }

    #[test]
    fn test_dict() {
        let mut dict = init_dict(1000001);
        let last = dict.get(1000000);
        assert_eq!(last, 1000000, "invalid result");
    }

    #[test]
    fn test_fibonacci() {
        assert_eq!(fib(0, 1, 10), 55, "invalid result");
        assert_eq!(fib(0, 1, 2000000), 0x79495858064f7881b9eff3a923642b2990b5a4342da5470eb2251df58d9acfb, "invalid result");
    }

    #[test]
    fn test_linear_search() {
        let array = init_array(4001);

        let index = search(@array, 1000);
        assert_eq!(index, 1000, "invalid result");
        let index = search(@array, 2000);
        assert_eq!(index, 2000, "invalid result");
        let index = search(@array, 3000);
        assert_eq!(index, 3000, "invalid result");
        let index = search(@array, 4000);
        assert_eq!(index, 4000, "invalid result");
    }
}
