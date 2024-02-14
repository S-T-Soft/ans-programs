import credits.aleo;
import ans_coupon_card_v1.aleo;
import aleo_name_service_registry_v3.aleo;

program ans_registrar_v4.aleo {
    mapping general_settings: u8 => u128;

    function get_name_length(name: [u128; 4]) -> u8 {
        let val: u128 = name[0u8];
        if (val > 4294967295u128) {
            return 5u8;
        }
        if (val > 16777215u128) {
            return 4u8;
        }
        if (val > 65535u128) {
            return 3u8;
        }
        if (val > 255u128) {
            return 2u8;
        }
        return 1u8;
    }

    function calc_price(length: u8) -> u64 {
        if (length == 5u8) {
            return 2000000u64;
        }
        if (length == 4u8) {
            return 10000000u64;
        }
        if (length == 3u8) {
            return 50000000u64;
        }
        if (length == 2u8) {
            return 250000000u64;
        }
        return 1250000000u64;
    }

    transition initialize_registrar() {
        let admin: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(admin);
    }

    finalize initialize_registrar(
        admin: u128
    ) {
        general_settings.set(0u8, admin);
    }

    transition set_minting_flag(
        flag: u128,
        cc_flag: u128
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(hash_caller, flag, cc_flag);
    }

    finalize set_minting_flag(
        hash_caller: u128,
        flag: u128,
        cc_flag: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
        general_settings.set(1u8, flag);
        general_settings.set(2u8, cc_flag);
    }

    transition change_admin(
        private admin: address
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let new_admin: u128 = BHP256::hash_to_u128(admin);
        return then finalize(hash_caller, new_admin);
    }

    finalize change_admin(
        public hash_caller: u128,
        public new_admin: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
        general_settings.set(7u8, new_admin); // Admin hash address
    }

    // register with coupon card
    transition register_free(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card_v1.aleo/CouponCard
    ) {
        assert_eq(card.discount_percent, 0u8);
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v1.aleo/use(card);
        return then finalize();
    }

    finalize register_free() {
        // check minting flag
        assert_eq(general_settings.get(2u8), 1u128);
    }

    // register a first level domain
    transition register_fld(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits
    ) {
        let length: u8 = get_name_length(name);
        // calc price
        let price: u64 = calc_price(length);
        // this program address receive credits
        let program_address: address = aleo1zqg7j94yne3e3kmwgs9h75yuz2ukw97w9xsvmdd32jnw8xz54cqsel9jrx;
        credits.aleo/transfer_private_to_public(pay_record, program_address, price);
        aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        return then finalize();
    }

    finalize register_fld() {
        // check minting flag
        assert_eq(general_settings.get(1u8), 1u128);
    }

    // register with coupon card
    transition register_fld_with_coupon(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits,
        card: ans_coupon_card_v1.aleo/CouponCard
    ) {
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        // calc price
        let price: u64 = calc_price(length);
        // discount
        price = price * card.discount_percent as u64 / 100u64;
        // this program address receive credits
        let program_address: address = aleo1zqg7j94yne3e3kmwgs9h75yuz2ukw97w9xsvmdd32jnw8xz54cqsel9jrx;
        credits.aleo/transfer_private_to_public(pay_record, program_address, price);
        aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v1.aleo/use(card);
        return then finalize();
    }

    finalize register_fld_with_coupon() {
        // check minting flag
        assert_eq(general_settings.get(2u8), 1u128);
    }

    transition claim(amount: u64, receiver: address) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        credits.aleo/transfer_public_to_private(receiver, amount);
        return then finalize(hash_caller);
    }

    finalize claim(hash_caller: u128) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
    }
}
