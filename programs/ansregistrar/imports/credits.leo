program credits.aleo {
    record credits {
        // The token owner.
        owner: address,
        // The token amount.
        microcredits: u64,
    }

    transition transfer_private_to_public(sender: credits, public receiver: address, public amount: u64) {}

    transition transfer_public_to_private(private receiver: address, public amount: u64){}

}