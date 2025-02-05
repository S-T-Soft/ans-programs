import messenger.aleo;
import ans_utils.aleo;
import aleo_name_service_registry.aleo;
import ans_coupon_card.aleo;
import credits.aleo;
import token_registry.aleo;
import wrapped_credits.aleo;
import validator_oracle.aleo;
import paleo_token.aleo;
import pondo_protocol_token.aleo;
import delegator1.aleo;
import delegator2.aleo;
import delegator3.aleo;
import delegator4.aleo;
import delegator5.aleo;
import pondo_protocol.aleo;
import ans_registrar.aleo;
program ans_registrar_quest.aleo;

struct NameStruct:
    name as [u128; 4u32];
    parent as field;
    resolver as field;

struct data:
    metadata as [field; 4u32];

struct TokenMetadata:
    token_id as field;
    name as u128;
    symbol as u128;
    decimals as u8;
    supply as u128;
    max_supply as u128;
    admin as address;
    external_authorization_required as boolean;
    external_authorization_party as address;

struct TokenOwner:
    account as address;
    token_id as field;

struct admin_operation:
    arg as field;
    op_type as u8;
    request_id as u64;

struct validator_state:
    validator as address;
    commission as u8;

function register_free:
    input r0 as [u128; 4u32].private;
    input r1 as field.private;
    input r2 as address.private;
    input r3 as ans_coupon_card.aleo/CouponCard.record;
    input r4 as [field; 8u32].private;
    call ans_registrar.aleo/register_free r0 r1 r2 r3 into r5;
    call messenger.aleo/send aleo1anscwvx9zhwm3yyzgef8c3nt36tmm0g4juhk4gxeavcwcz7t6v9qwnlue9 r4 into r6;
    async register_free r5 into r7;
    output r7 as ans_registrar_quest.aleo/register_free.future;

finalize register_free:
    input r0 as ans_registrar.aleo/register_free.future;
    await r0;

function register_fld:
    input r0 as [u128; 4u32].private;
    input r1 as field.private;
    input r2 as address.private;
    input r3 as credits.aleo/credits.record;
    input r4 as [field; 8u32].private;
    call ans_registrar.aleo/register_fld r0 r1 r2 r3 into r5;
    call messenger.aleo/send aleo1anscwvx9zhwm3yyzgef8c3nt36tmm0g4juhk4gxeavcwcz7t6v9qwnlue9 r4 into r6;
    async register_fld r5 into r7;
    output r7 as ans_registrar_quest.aleo/register_fld.future;

finalize register_fld:
    input r0 as ans_registrar.aleo/register_fld.future;
    await r0;

function register_fld_public:
    input r0 as [u128; 4u32].private;
    input r1 as field.private;
    input r2 as address.private;
    input r3 as [field; 8u32].private;
    call ans_registrar.aleo/register_fld_public r0 r1 r2 into r4;
    call messenger.aleo/send aleo1anscwvx9zhwm3yyzgef8c3nt36tmm0g4juhk4gxeavcwcz7t6v9qwnlue9 r3 into r5;
    async register_fld_public r4 into r6;
    output r6 as ans_registrar_quest.aleo/register_fld_public.future;

finalize register_fld_public:
    input r0 as ans_registrar.aleo/register_fld_public.future;
    await r0;

function register_fld_with_coupon:
    input r0 as [u128; 4u32].private;
    input r1 as field.private;
    input r2 as address.private;
    input r3 as credits.aleo/credits.record;
    input r4 as ans_coupon_card.aleo/CouponCard.record;
    input r5 as [field; 8u32].private;
    call ans_registrar.aleo/register_fld_with_coupon r0 r1 r2 r3 r4 into r6;
    call messenger.aleo/send aleo1anscwvx9zhwm3yyzgef8c3nt36tmm0g4juhk4gxeavcwcz7t6v9qwnlue9 r5 into r7;
    async register_fld_with_coupon r6 into r8;
    output r8 as ans_registrar_quest.aleo/register_fld_with_coupon.future;

finalize register_fld_with_coupon:
    input r0 as ans_registrar.aleo/register_fld_with_coupon.future;
    await r0;

function register_fld_with_coupon_public:
    input r0 as [u128; 4u32].private;
    input r1 as field.private;
    input r2 as address.private;
    input r3 as ans_coupon_card.aleo/CouponCard.record;
    input r4 as [field; 8u32].private;
    call ans_registrar.aleo/register_fld_with_coupon_public r0 r1 r2 r3 into r5;
    call messenger.aleo/send aleo1anscwvx9zhwm3yyzgef8c3nt36tmm0g4juhk4gxeavcwcz7t6v9qwnlue9 r4 into r6;
    async register_fld_with_coupon_public r5 into r7;
    output r7 as ans_registrar_quest.aleo/register_fld_with_coupon_public.future;

finalize register_fld_with_coupon_public:
    input r0 as ans_registrar.aleo/register_fld_with_coupon_public.future;
    await r0;
