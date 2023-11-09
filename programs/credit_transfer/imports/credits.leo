program credits.aleo {
    record credits {
        // The token owner.
        owner: address,
        // The token amount.
        microcredits: u64,
    }

    transition transfer_private_to_public(sender: credits, public receiver: address, public amount: u64) -> credits {
        return credits {
            owner: receiver,
            microcredits: amount,
        } then finalize();
    }

    finalize transfer_private_to_public() {
        assert(true);
    }

    transition transfer_public_to_private(private receiver: address, public amount: u64) -> credits {
        return credits {
            owner: receiver,
            microcredits: amount,
        } then finalize();
    }

    finalize transfer_public_to_private() {
        assert(true);
    }

}