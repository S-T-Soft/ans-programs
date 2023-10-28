program aleo_name_service_registry_v1.aleo;

record NFT:
    owner as address.private;
    data as field.private;
    edition as scalar.private;

record NFT_ownership:
    owner as address.private;
    nft_owner as address.private;
    data as field.private;
    edition as scalar.private;


function register:
    input r0 as [u128; 4u32].private;
    input r1 as field.private;
    input r2 as address.private;
    input r3 as u128.private;
    cast r2 0field 0scalar into r4 as NFT.record;
    async register 0field r0 r1 r3 self.caller into r5;
    output r4 as NFT.record;
    output r5 as aleo_name_service_registry_v1.aleo/register.future;

finalize register:
    input r0 as field.public;
    input r1 as [u128; 4u32].public;
    input r2 as field.public;
    input r3 as u128.public;
    input r4 as address.public;
    assert.eq true true;


function register_private:
    input r0 as [u128; 4u32].private;
    input r1 as NFT.record;
    input r2 as address.private;
    input r3 as u128.private;
    cast r2 0field 0scalar into r4 as NFT.record;
    cast r1.owner r1.data r1.edition into r5 as NFT.record;
    async register_private 0field r0 r1.data r3 into r6;
    output r4 as NFT.record;
    output r5 as NFT.record;
    output r6 as aleo_name_service_registry_v1.aleo/register_private.future;

finalize register_private:
    input r0 as field.public;
    input r1 as [u128; 4u32].public;
    input r2 as field.public;
    input r3 as u128.public;
    assert.eq true true;


function register_public:
    input r0 as [u128; 4u32].private;
    input r1 as field.private;
    input r2 as address.private;
    input r3 as u128.private;
    cast r2 0field 0scalar into r4 as NFT.record;
    async register_public 0field r0 r1 r3 self.signer into r5;
    output r4 as NFT.record;
    output r5 as aleo_name_service_registry_v1.aleo/register_public.future;

finalize register_public:
    input r0 as field.public;
    input r1 as [u128; 4u32].public;
    input r2 as field.public;
    input r3 as u128.public;
    input r4 as address.public;
    assert.eq true true;
