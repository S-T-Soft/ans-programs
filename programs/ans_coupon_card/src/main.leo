// The 'ans_coupon_card' program.
program ans_coupon_card_v2.aleo {
    record CouponCard {
        owner: address,
        // 1 means register price is: origin_price * 0.01
        discount_percent: u8,
        limit_name_length: u8,
        tld: field
    }

    struct CardOwner {
        account: address,
        discount_percent: u8,
        limit_name_length: u8,
        tld: field
    }

    // 0 admin
    mapping admins: u8 => address;

    // address holding cards
    mapping cards: field => u64;

    async transition initialize() -> Future {
        return finalize_initialize(self.caller);
    }

    async function finalize_initialize(
        admin: address
    ) {
        let current_admin: address = admins.get_or_use(0u8, self.address);
        assert_eq(current_admin, self.address);

        admins.set(0u8, admin);
    }

    async transition set_admin(
        admin: address
    ) -> Future {
        return finalize_set_admin(self.caller, admin);
    }

    async function finalize_set_admin(
        public caller: address,
        public admin: address,
    ) {
        // check admin
        assert_eq(admins.get(0u8), caller);
        admins.set(0u8, admin);
    }

    transition transfer_private(
        card: CouponCard,
        private receiver: address
    ) -> CouponCard {
        return CouponCard {
            owner: receiver,
            discount_percent: card.discount_percent,
            limit_name_length: card.limit_name_length,
            tld: card.tld
        };
    }

    async transition transfer_private_to_public(
        card: CouponCard,
        public receiver: address
    ) -> Future {
        let card_owner: CardOwner = CardOwner {
            account: receiver,
            discount_percent: card.discount_percent,
            limit_name_length: card.limit_name_length,
            tld: card.tld
        };
        let key: field = BHP256::hash_to_field(card_owner);
        return finalize_transfer_private_to_public(key);
    }

    async function finalize_transfer_private_to_public (key: field) {
        let count: u64 = cards.get_or_use(key, 0u64);
        cards.set(key, count + 1u64);
    }

    async transition transfer_public_to_private (
        receiver: address,
        discount_percent: u8,
        limit_name_length: u8,
        tld: field
    ) -> (CouponCard, Future) {
        let card_owner: CardOwner = CardOwner {
            account: self.caller,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld
        };
        let key: field = BHP256::hash_to_field(card_owner);
        return (CouponCard {
            owner: receiver,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld
        }, finalize_transfer_public_to_private(key));
    }

    async function finalize_transfer_public_to_private (key: field) {
        let count: u64 = cards.get(key);
        assert(count > 0u64);
        cards.set(key, count - 1u64);
    }

    async transition transfer_public(
        receiver: address,
        discount_percent: u8,
        limit_name_length: u8,
        tld: field,
        count: u64
    ) -> Future {
        let card_owner: CardOwner = CardOwner {
            account: self.caller,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld
        };
        let key: field = BHP256::hash_to_field(card_owner);
        let to_card_owner: CardOwner = CardOwner {
            account: receiver,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld
        };
        let to_key: field = BHP256::hash_to_field(to_card_owner);
        return finalize_transfer_public(key, to_key, count);
    }

    async function finalize_transfer_public(
        key: field,
        to_key: field,
        count: u64
    ) {
        let current_count: u64 = cards.get(key);
        assert(current_count >= count);
        cards.set(key, current_count - count);
        let to_current_count: u64 = cards.get_or_use(to_key, 0u64);
        cards.set(to_key, to_current_count + count);
    }

    // issue a coupon card
    async transition issue_coupon_card(
        receiver: address,
        discount_percent: u8,
        limit_name_length: u8,
        tld: field
    ) -> (CouponCard, Future) {
        assert(discount_percent < 100u8);
        let card: CouponCard = CouponCard{
            owner: receiver,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld
        };
        return (card, finalize_issue_coupon_card(self.caller));
    }

    async function finalize_issue_coupon_card(
        caller: address
    ) {
        // check admin
        assert_eq(admins.get(0u8), caller);
    }

    // issue some public coupon cards
    async transition issue_coupon_card_public(
        receiver: address,
        discount_percent: u8,
        limit_name_length: u8,
        tld: field,
        count: u64
    ) -> Future {
        assert(discount_percent < 100u8);
        let card_owner: CardOwner = CardOwner {
            account: receiver,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld
        };
        let key: field = BHP256::hash_to_field(card_owner);
        return finalize_issue_coupon_card_public(self.caller, key, count);
    }

    async function finalize_issue_coupon_card_public(
        caller: address,
        key: field,
        count: u64
    ) {
        // check admin
        assert_eq(admins.get(0u8), caller);
        let current_count: u64 = cards.get_or_use(key, 0u64);
        cards.set(key, current_count + count);
    }

    transition use(card: CouponCard) {}
}
