// The 'ans_coupon_card' program.
program ans_coupon_card_v1.aleo {
    record CouponCard {
        owner: address,
        // 1 means register price is: origin_price * 0.01
        discount_percent: u8,
        limit_name_length: u8,
        tld: field
    }

    // 0 admin
    // 1 coinbase issue address
    // 2 max issue coinbase card
    // 3 current issued coinbase card
    mapping general_settings: u8 => u128;

    mapping cb_uuids: u128 => bool;
    mapping cb_address: u128 => bool;

    transition initialize() {
        let admin: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(admin);
    }

    finalize initialize(
        admin: u128
    ) {
        general_settings.set(0u8, admin);
    }

    transition set_setting(
        private key: u8,
        private value: u128
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(hash_caller, key, value);
    }

    finalize set_setting(
        public hash_caller: u128,
        public key: u8,
        public value: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
        general_settings.set(key, value);
    }

    // issue a coupon card
    transition issue_coupon_card(
        receiver: address,
        discount_percent: u8,
        limit_name_length: u8,
        tld: field
    ) -> CouponCard {
        assert(discount_percent <= 100u8);
        let card: CouponCard = CouponCard{
            owner: receiver,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld
        };
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return card then finalize(hash_caller);
    }

    finalize issue_coupon_card(
        hash_caller: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
    }

    // issue a coupon card
    transition issue_coupon_card_cb(
        receiver: address,
        cb_uuid: [u128; 4]
    ) -> CouponCard {
        let card: CouponCard = CouponCard {
            owner: receiver,
            discount_percent: 0u8,
            limit_name_length: 5u8,
            // .anon
            tld: 3429962289057708737616101644642461578953781498069508461288569895276398934019field
        };
        let hash_receiver: u128 = BHP256::hash_to_u128(receiver);
        let hash_cb_uuid: u128 = BHP256::hash_to_u128(cb_uuid);
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return card then finalize(hash_caller, hash_receiver, hash_cb_uuid);
    }

    finalize issue_coupon_card_cb(
        hash_caller: u128,
        hash_receiver: u128,
        hash_cb_uuid: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(1u8));
        assert_eq(cb_uuids.contains(hash_cb_uuid), false);
        assert_eq(cb_address.contains(hash_receiver), false);
        let current_issued: u128 = general_settings.get(3u8);
        assert(general_settings.get(2u8) > current_issued);
        cb_uuids.set(hash_cb_uuid, true);
        cb_address.set(hash_receiver, true);
        general_settings.set(3u8, current_issued + 1u128);
    }

    transition use(card: CouponCard) {}
}
