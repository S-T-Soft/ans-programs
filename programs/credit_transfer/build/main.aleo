import credits.aleo;
import aleo_name_service_registry_v3.aleo;
program ans_credit_transfer_v3.aleo;














mapping domain_credits:
	key as field.public;
	value as u64.public;

function transfer_credits:
    input r0 as field.private;
    input r1 as [u128; 4u32].private;
    input r2 as u64.private;
    input r3 as credits.aleo/credits.record;
    call credits.aleo/transfer_private_to_public r3 aleo1jvpk02xw8kp9cl48km49n0er8rr9fkamyph9yxsnynl7ufgx2y9q7qvqfg r2 into r4 r5;
    hash.psd2 r1 into r6 as scalar;
    commit.bhp256 r0 r6 into r7 as field;
    async transfer_credits r5 r7 r2 into r8;
    output r8 as ans_credit_transfer_v3.aleo/transfer_credits.future;

finalize transfer_credits:
    input r0 as credits.aleo/transfer_private_to_public.future;
    input r1 as field.public;
    input r2 as u64.public;
    await r0;
    get.or_use domain_credits[r1] 0u64 into r3;
    add r3 r2 into r4;
    set r4 into domain_credits[r1];


function claim_credits_private:
    input r0 as aleo_name_service_registry_v3.aleo/NFT.record;
    input r1 as [u128; 4u32].private;
    input r2 as u64.private;
    call credits.aleo/transfer_public_to_private self.caller r2 into r3 r4;
    hash.psd2 r1 into r5 as scalar;
    commit.bhp256 r0.data r5 into r6 as field;
    async claim_credits_private r4 r6 r2 into r7;
    output r7 as ans_credit_transfer_v3.aleo/claim_credits_private.future;

finalize claim_credits_private:
    input r0 as credits.aleo/transfer_public_to_private.future;
    input r1 as field.public;
    input r2 as u64.public;
    await r0;
    get domain_credits[r1] into r3;
    gte r3 r2 into r4;
    assert.eq r4 true;
    sub r3 r2 into r5;
    set r5 into domain_credits[r1];


function claim_credits_public:
    input r0 as field.private;
    input r1 as [u128; 4u32].private;
    input r2 as u64.private;
    call aleo_name_service_registry_v3.aleo/is_owner r0 self.caller into r3;
    call credits.aleo/transfer_public_to_private self.caller r2 into r4 r5;
    hash.psd2 r1 into r6 as scalar;
    commit.bhp256 r0 r6 into r7 as field;
    async claim_credits_public r3 r5 r0 r7 r2 into r8;
    output r8 as ans_credit_transfer_v3.aleo/claim_credits_public.future;

finalize claim_credits_public:
    input r0 as aleo_name_service_registry_v3.aleo/is_owner.future;
    input r1 as credits.aleo/transfer_public_to_private.future;
    input r2 as field.public;
    input r3 as field.public;
    input r4 as u64.public;
    await r0;
    await r1;
    get domain_credits[r3] into r5;
    gte r5 r4 into r6;
    assert.eq r6 true;
    sub r5 r4 into r7;
    set r7 into domain_credits[r3];
