program ans_coupon_card_v1.aleo;

record CouponCard:
    owner as address.private;
    discount_percent as u8.private;
    limit_name_length as u8.private;
    tld as field.private;

mapping general_settings:
    key as u8.public;
    value as u128.public;

function initialize:
    hash.bhp256 self.caller into r0 as u128;
    async initialize r0 into r1;
    output r1 as ans_coupon_card_v1.aleo/initialize.future;

finalize initialize:
    input r0 as u128.public;
    set r0 into general_settings[0u8];

function issue_coupon_card:
    input r0 as address.private;
    input r1 as u8.private;
    input r2 as u8.private;
    input r3 as field.private;
    lte r1 100u8 into r4;
    assert.eq r4 true ;
    cast r0 r1 r2 r3 into r5 as CouponCard.record;
    hash.bhp256 self.caller into r6 as u128;
    async issue_coupon_card r6 into r7;
    output r5 as CouponCard.record;
    output r7 as ans_coupon_card_v1.aleo/issue_coupon_card.future;

finalize issue_coupon_card:
    input r0 as u128.public;
    get general_settings[0u8] into r1;
    assert.eq r0 r1 ;

function use:
    input r0 as CouponCard.record;
