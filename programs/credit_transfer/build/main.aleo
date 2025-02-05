import credits.aleo;
import multi_token_support_program.aleo;
import ans_utils.aleo;
import aleo_name_service_registry_v1.aleo;
program ans_credit_transfer_v1.aleo;


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


struct Name:
    name as [u128; 4u32];
    parent as field;

struct NameStruct:
    name as [u128; 4u32];
    parent as field;
    resolver as u128;

struct data:
    metadata as [field; 4u32];
    content as Name;



struct NameTokenPair:
    name_hash as field;
    token_id as field;


mapping domain_credits:
	key as field.public;
	value as u64.public;


mapping domain_tokens:
	key as field.public;
	value as u128.public;


function transfer_credits:
    input r0 as field.private;
    input r1 as [u128; 2u32].private;
    input r2 as u64.private;
    input r3 as credits.aleo/credits.record;
    call credits.aleo/transfer_private_to_public r3 ans_credit_transfer_v1.aleo r2 into r4 r5;
    hash.psd2 r1 into r6 as scalar;
    commit.bhp256 r0 r6 into r7 as field;
    async transfer_credits r5 r7 r2 into r8;
    output r8 as ans_credit_transfer_v1.aleo/transfer_credits.future;

finalize transfer_credits:
    input r0 as credits.aleo/transfer_private_to_public.future;
    input r1 as field.public;
    input r2 as u64.public;
    await r0;
    get.or_use domain_credits[r1] 0u64 into r3;
    add r3 r2 into r4;
    set r4 into domain_credits[r1];




function transfer_credits_public:
    input r0 as field.private;
    input r1 as [u128; 2u32].private;
    input r2 as u64.private;
    call credits.aleo/transfer_public_as_signer ans_credit_transfer_v1.aleo r2 into r3;
    hash.psd2 r1 into r4 as scalar;
    commit.bhp256 r0 r4 into r5 as field;
    async transfer_credits_public r3 r5 r2 into r6;
    output r6 as ans_credit_transfer_v1.aleo/transfer_credits_public.future;

finalize transfer_credits_public:
    input r0 as credits.aleo/transfer_public_as_signer.future;
    input r1 as field.public;
    input r2 as u64.public;
    await r0;
    get.or_use domain_credits[r1] 0u64 into r3;
    add r3 r2 into r4;
    set r4 into domain_credits[r1];




function claim_credits_private:
    input r0 as aleo_name_service_registry_v1.aleo/NFT.record;
    input r1 as [u128; 2u32].private;
    input r2 as u64.private;
    call credits.aleo/transfer_public_to_private self.caller r2 into r3 r4;
    hash.psd2 r1 into r5 as scalar;
    commit.bhp256 r0.data.metadata[0u32] r5 into r6 as field;
    async claim_credits_private r4 r6 r2 into r7;
    output r7 as ans_credit_transfer_v1.aleo/claim_credits_private.future;

finalize claim_credits_private:
    input r0 as credits.aleo/transfer_public_to_private.future;
    input r1 as field.public;
    input r2 as u64.public;
    await r0;
    get domain_credits[r1] into r3;
    sub r3 r2 into r4;
    set r4 into domain_credits[r1];




function claim_credits_public:
    input r0 as field.private;
    input r1 as [u128; 2u32].private;
    input r2 as u64.private;
    call credits.aleo/transfer_public_to_private self.caller r2 into r3 r4;
    hash.psd2 r1 into r5 as scalar;
    commit.bhp256 r0 r5 into r6 as field;
    async claim_credits_public r4 r0 self.caller r6 r2 into r7;
    output r7 as ans_credit_transfer_v1.aleo/claim_credits_public.future;

finalize claim_credits_public:
    input r0 as credits.aleo/transfer_public_to_private.future;
    input r1 as field.public;
    input r2 as address.public;
    input r3 as field.public;
    input r4 as u64.public;
    await r0;
    get aleo_name_service_registry_v1.aleo/nft_owners[r1] into r5;
    assert.eq r2 r5;
    get domain_credits[r3] into r6;
    sub r6 r4 into r7;
    set r7 into domain_credits[r3];




function transfer_token:
    input r0 as field.private;
    input r1 as field.private;
    input r2 as [u128; 2u32].private;
    input r3 as u128.private;
    input r4 as multi_token_support_program.aleo/Token.record;
    call multi_token_support_program.aleo/transfer_private_to_public ans_credit_transfer_v1.aleo r3 r4 into r5 r6;
    hash.psd2 r2 into r7 as scalar;
    cast r1 r0 into r8 as NameTokenPair;
    commit.bhp256 r8 r7 into r9 as field;
    async transfer_token r6 r9 r3 into r10;
    output r10 as ans_credit_transfer_v1.aleo/transfer_token.future;

finalize transfer_token:
    input r0 as multi_token_support_program.aleo/transfer_private_to_public.future;
    input r1 as field.public;
    input r2 as u128.public;
    await r0;
    get.or_use domain_tokens[r1] 0u128 into r3;
    add r3 r2 into r4;
    set r4 into domain_tokens[r1];




function transfer_token_public:
    input r0 as field.private;
    input r1 as field.private;
    input r2 as [u128; 2u32].private;
    input r3 as u128.private;
    call multi_token_support_program.aleo/transfer_public_as_signer r0 ans_credit_transfer_v1.aleo r3 into r4;
    hash.psd2 r2 into r5 as scalar;
    cast r1 r0 into r6 as NameTokenPair;
    commit.bhp256 r6 r5 into r7 as field;
    async transfer_token_public r4 r7 r3 into r8;
    output r8 as ans_credit_transfer_v1.aleo/transfer_token_public.future;

finalize transfer_token_public:
    input r0 as multi_token_support_program.aleo/transfer_public_as_signer.future;
    input r1 as field.public;
    input r2 as u128.public;
    await r0;
    get.or_use domain_tokens[r1] 0u128 into r3;
    add r3 r2 into r4;
    set r4 into domain_tokens[r1];




function claim_token_private:
    input r0 as field.private;
    input r1 as aleo_name_service_registry_v1.aleo/NFT.record;
    input r2 as [u128; 2u32].private;
    input r3 as u128.private;
    input r4 as boolean.private;
    call multi_token_support_program.aleo/transfer_public_to_private r0 self.caller r3 r4 into r5 r6;
    hash.psd2 r2 into r7 as scalar;
    cast r1.data.metadata[0u32] r0 into r8 as NameTokenPair;
    commit.bhp256 r8 r7 into r9 as field;
    async claim_token_private r6 r9 r3 into r10;
    output r10 as ans_credit_transfer_v1.aleo/claim_token_private.future;

finalize claim_token_private:
    input r0 as multi_token_support_program.aleo/transfer_public_to_private.future;
    input r1 as field.public;
    input r2 as u128.public;
    await r0;
    get domain_tokens[r1] into r3;
    sub r3 r2 into r4;
    set r4 into domain_tokens[r1];




function claim_token_public:
    input r0 as field.private;
    input r1 as field.private;
    input r2 as [u128; 2u32].private;
    input r3 as u128.private;
    input r4 as boolean.private;
    call multi_token_support_program.aleo/transfer_public_to_private r0 self.caller r3 r4 into r5 r6;
    hash.psd2 r2 into r7 as scalar;
    cast r1 r0 into r8 as NameTokenPair;
    commit.bhp256 r8 r7 into r9 as field;
    async claim_token_public r6 r1 self.caller r9 r3 into r10;
    output r10 as ans_credit_transfer_v1.aleo/claim_token_public.future;

finalize claim_token_public:
    input r0 as multi_token_support_program.aleo/transfer_public_to_private.future;
    input r1 as field.public;
    input r2 as address.public;
    input r3 as field.public;
    input r4 as u128.public;
    await r0;
    get aleo_name_service_registry_v1.aleo/nft_owners[r1] into r5;
    assert.eq r2 r5;
    get domain_tokens[r3] into r6;
    sub r6 r4 into r7;
    set r7 into domain_tokens[r3];

