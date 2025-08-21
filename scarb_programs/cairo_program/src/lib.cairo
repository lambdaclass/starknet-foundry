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

#[cfg(test)]
mod tests {
    use super::factorial;

    #[test]
    fn test_factorial() {
        assert_eq!(factorial(1, 2), 2, "bad factorial");
        assert_eq!(factorial(1, 3), 6, "bad factorial");
        assert_eq!(factorial(1, 4), 24, "bad factorial");
        assert_eq!(factorial(1, 10), 3628800, "bad factorial");
        assert_eq!(factorial(1, 2000000), 0x4d6e41de886ac83938da3456ccf1481182687989ead34d9d35236f0864575a0, "bad factorial");
    }
}
