# ERC20Revertable

ERC20Revertable is a simple ERC20 token that allow to revert lost tokens to the sender.

## Revert Conditions

- If the recipient never transfered the tokens of that ERC20 before, the sender can request to revert the tokens to the sender.
- If the sender requested to revert the tokens to the sender, the sender needs to wait for 30 days to revert the tokens to the sender.
- If the recipient disputed on the revert once, the sender and any future sender can't revert the tokens to the sender.
- If the recipient is a contract, the sender can't revert the tokens.
- If the recipient ever used the tokens of that ERC20, i.e transferd/approved before, the sender can't revert the tokens to the sender.

## Intended Use

- After a sender accidentally sends his tokens to a wrong address, the sender calls `requestTransferRevert(address recipient)` to revert the tokens to the sender.
- The recipient can dispute on the revert by calling `disputeTransferRevert()` if the recipient was a real person and never used that token yet before.
- The sender has to wait 30 days to allow the recipient to dispute at anytime.
- After this period the sender can call `transferRevert(address recipient)` to revert the tokens to the sender. which eventually will check if the recipient disputed or not.