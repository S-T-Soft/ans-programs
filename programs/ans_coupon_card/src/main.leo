// The 'ans_coupon_card' program.
program ans_coupon_card_v3.aleo {
    const ADMIN_ADDR: address = aleo1sr8d93usu395zc29qcl35ul2e7hl2538hl8pehe4ms88q4g70gxq3ffw0v;

    record CouponCard {
        owner: address,
        // 1 means register price is: origin_price * 0.01
        discount_percent: u8,
        limit_name_length: u8,
        tld: field,
        count: u64
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
        return finalize_initialize();
    }

    async function finalize_initialize() {
        let current_admin: address = admins.get_or_use(0u8, self.address);
        assert_eq(current_admin, self.address);

        admins.set(0u8, ADMIN_ADDR);
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
        receiver: address,
        count: u64
    ) -> (CouponCard, CouponCard) {
        let new_card: CouponCard = CouponCard {
            owner: receiver,
            discount_percent: card.discount_percent,
            limit_name_length: card.limit_name_length,
            tld: card.tld,
            count: count
        };
        let remain_card: CouponCard = CouponCard {
            owner: card.owner,
            discount_percent: card.discount_percent,
            limit_name_length: card.limit_name_length,
            tld: card.tld,
            count: card.count - count
        };
        return (new_card, remain_card);
    }

    async transition transfer_private_to_public(
        card: CouponCard,
        public receiver: address,
        count: u64
    ) -> (CouponCard, Future) {
        let card_owner: CardOwner = CardOwner {
            account: receiver,
            discount_percent: card.discount_percent,
            limit_name_length: card.limit_name_length,
            tld: card.tld
        };
        let remain_card: CouponCard = CouponCard {
            owner: card.owner,
            discount_percent: card.discount_percent,
            limit_name_length: card.limit_name_length,
            tld: card.tld,
            count: card.count - count
        };
        let key: field = BHP256::hash_to_field(card_owner);
        let f: Future = transfer_private_to_pub(key, count);
        return (remain_card, f);
    }

    async function transfer_private_to_pub (
        key: field,
        count: u64
    ) {
        let current_count: u64 = cards.get_or_use(key, 0u64);
        cards.set(key, current_count + count);
    }

    async transition transfer_public_to_private (
        receiver: address,
        discount_percent: u8,
        limit_name_length: u8,
        tld: field,
        count: u64
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
            tld: tld,
            count: count
        }, transfer_public_to_priv(key, count));
    }

    async function transfer_public_to_priv (
        key: field,
        count: u64
    ) {
        let current_count: u64 = cards.get(key);
        assert(current_count >= count);
        cards.set(key, current_count - count);
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
        tld: field,
        count: u64
    ) -> (CouponCard, Future) {
        assert(discount_percent < 100u8);
        let card: CouponCard = CouponCard{
            owner: receiver,
            discount_percent: discount_percent,
            limit_name_length: limit_name_length,
            tld: tld,
            count: count
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
        return issue_coupon_card_pub(self.caller, key, count);
    }

    async function issue_coupon_card_pub(
        caller: address,
        key: field,
        count: u64
    ) {
        // check admin
        assert_eq(admins.get(0u8), caller);
        let current_count: u64 = cards.get_or_use(key, 0u64);
        cards.set(key, current_count + count);
    }

    transition use(card: CouponCard) -> CouponCard {
        assert(card.count > 0u64);
        return CouponCard {
            owner: card.owner,
            discount_percent: card.discount_percent,
            limit_name_length: card.limit_name_length,
            tld: card.tld,
            count: card.count - 1u64
        };
    }
}
