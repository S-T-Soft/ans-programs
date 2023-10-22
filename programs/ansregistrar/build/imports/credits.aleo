program credits.aleo;

record credits:
    owner as address.private;
    microcredits as u64.private;


function transfer_private_to_public:
    input r0 as credits.record;
    input r1 as address.public;
    input r2 as u64.public;


function transfer_public_to_private:
    input r0 as address.private;
    input r1 as u64.public;
