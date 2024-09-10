// The 'ans_utils' program.
program ans_utils.aleo {
    // Validate the ASCII bits of a domain name
    inline validate_name_bit(val: u128) -> bool {
        for i: u8 in 0u8 .. 16u8 {
            let new: u128 = val.shr(i * 8u8);
            let b: u128 = new & 255u128;
            // Check if the ASCII bit is valid, 0-9, a-z, -, _
            if (! (b == 0u128 || b == 45u128 || b == 95u128 || (b >= 48u128 && b <= 57u128) || (b >= 97u128 && b <= 122u128))) {
                return false;
            }
        }
        return true;
    }

    transition validate_name(name: [u128; 4]) -> bool {
        // Check if the name is empty
        assert_neq(name[0u8], 0u128);
        let is_valid: bool = true;
        for i: u8 in 0u8 .. 4u8 {
            is_valid = is_valid && validate_name_bit(name[i]);
        }
        return is_valid;
    }
}
