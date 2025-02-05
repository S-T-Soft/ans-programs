// The 'messenger' program.
program messenger.aleo {
    record Message {
        owner: address,
        msg: [field; 8], // can store 248 bytes
        sender: address
    }

    transition send(to: address, msg: [field; 8]) -> Message {
        return Message {
            owner: to,
            msg: msg,
            sender: self.caller
        };
    }
}
