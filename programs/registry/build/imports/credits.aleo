program credits.aleo;

record credits:
    owner as address.private;
    microcredits as u64.private;


function transfer_private_to_public:
    input r0 as credits.record;
    input r1 as address.public;
    input r2 as u64.public;
    cast r1 r2 into r3 as credits.record;
    async transfer_private_to_public into r4;
    output r3 as credits.record;
    output r4 as credits.aleo/transfer_private_to_public.future;

finalize transfer_private_to_public:
    assert.eq true true;


function transfer_public_to_private:
    input r0 as address.private;
    input r1 as u64.public;
    cast r0 r1 into r2 as credits.record;
    async transfer_public_to_private into r3;
    output r2 as credits.record;
    output r3 as credits.aleo/transfer_public_to_private.future;

finalize transfer_public_to_private:
    assert.eq true true;
