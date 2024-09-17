// The 'ans_utils' program.
program ans_utils_v2.aleo {
    transition validate_name(name: [u128; 4]) -> bool {
        // Check if the name is empty
        assert_neq(name[0u8], 0u128);
        let found_zero: bool = false;
        for i: u8 in 0u8 .. 4u8 {
            let val: u128 = name[i];
            for j: u8 in 0u8 .. 16u8 {
                let new: u128 = val.shr(j * 8u8);
                let b: u128 = new & 255u128;
                if (b == 0u128) {
                    found_zero = true;
                } else {
                    if found_zero {
                        return false;
                    }
                    if (! (b == 45u128 || b == 95u128 || (b >= 48u128 && b <= 57u128) || (b >= 97u128 && b <= 122u128))) {
                        return false;
                    }
                }
            }
        }
        return true;
    }
}
