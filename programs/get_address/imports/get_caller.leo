program get_caller.aleo {
    transition who() -> (address, address) {
        return (self.caller, self.signer);
    }
}