// The 'program' program.
import credits.leo;
import aleo_name_service_registry_v1.leo;

program ans_registrar_v1.aleo {
    mapping general_settings: u8 => u128;

    function calc_price(name: [u128; 4]) -> u64 {
        let mask: u128 = 255u128;
        let val: u128 = name[0u8];
        let price: u64 = 1250000000u64;
        for i: u8 in 1u8 .. 5u8 {
            let new: u128 = val.shr(i * 8u8);
            let b: u128 = new & mask;
            if (b > 0u128) {
                price /= 5u64;
            }
        }
        return price;
    }

    transition initialize() {
        let admin: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(admin);
    }

    finalize initialize(
        admin: u128
    ) {
        general_settings.set(0u8, admin);
        // set the minting flag
        general_settings.set(1u8, 1u128);
    }

    transition set_minting_flag(
        flag: u128
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(hash_caller, flag);
    }

    finalize set_minting_flag(
        hash_caller: u128,
        flag: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
        general_settings.set(1u8, flag);
    }

    transition set_admin(
        private admin: address
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let new_admin: u128 = BHP256::hash_to_u128(admin);
        return then finalize(hash_caller, new_admin);
    }

    finalize set_admin(
        public hash_caller: u128,
        public new_admin: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
        general_settings.set(7u8, new_admin); // Admin hash address
    }

    // register a first level domain
    // the self.caller must be the holder of parent ANS name, it can be a program or an account
    transition register_fld(
        name: [u128; 4],
        receiver: address,
        pay_record: credits.leo/credits
    ) {
        // calc price
        let price: u64 = calc_price(name);
        // this program address receive credits
        let program_address: address = aleo172lc2n6hcaqedj8kktf3sl03a5g8kt8hw0hj7vgp0d0tukn5w5pqcnruw0;
        credits.leo/transfer_private_to_public(pay_record, program_address, price);
        // this is "ans" name hash
        let parent: field = 3601410589032411677092457044111621862970800028849492457114786804129430260029field;
        aleo_name_service_registry_v1.leo/register(name, parent, receiver, 0u128);
        return then finalize();
    }

    finalize register_fld() {
        // check minting flag
        assert_eq(general_settings.get(1u8), 1u128);
    }

    transition claim(amount: u64, receiver: address) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        credits.leo/transfer_public_to_private(receiver, amount);
        return then finalize(hash_caller);
    }

    finalize claim(hash_caller: u128) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
    }

}
