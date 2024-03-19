// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Revertable
 * @dev ERC20Revertable is a basic ERC20 token with transfer reverting possibility.
 *
 * Rules to revert the transfer:
 * - The recipient is not a contract
 * - The recipient never disputed the transfer
 * - The recipient is not in the revert period
 * - The recipient is not a disputed address
 * - The recipient never did a transfer
 *
 */

contract ERC20Revertable is ERC20 {
    mapping(address => bool) private _disputed;
    mapping(address => uint256) private _disputePeriod;
    uint public constant DISPUTE_PERIOD = 30 days;
    // mapping address => address (sender => receiver) to handle transfers that might dispute
    // the receiver must not be disputed
    mapping(address => mapping(address => uint256)) private _transfers;

    error RecipientIsContract();
    error NoTransferToRevert();
    error DisputePeriodAlreadySet();
    error DisputePeriodNotSet();
    error DisputePeriodNotOver();
    error RecipientIsDisputed();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    modifier onlyRevertable(address recipient) {
        if (_disputed[recipient]) {
            revert RecipientIsDisputed();
        }
        if (isContract(recipient)) {
            revert RecipientIsContract();
        }
        if (_transfers[msg.sender][recipient] == 0) {
            revert NoTransferToRevert();
        }
        if (_disputePeriod[recipient] != 0) {
            revert DisputePeriodAlreadySet();
        }

        _;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        // if sender can transfer/approve then it is not a dead address
        if (!_disputed[from]) {
            _disputePeriod[from] = 0;
            _disputed[from] = true;
        }
        if (!_disputed[to] && !isContract(to)) {
            // will be checked in super._update anyway
            unchecked {
                _transfers[from][to] += value;
            }
        }
        super._update(from, to, value);
    }

    function disputeTransferRevert() external {
        _disputed[msg.sender] = true;
    }

    function isDisputed(address recipient) external view returns (bool) {
        return _disputed[recipient];
    }

    function disputePeriod(address recipient) external view returns (uint256) {
        return _disputePeriod[recipient];
    }

    function requestTransferRevert(
        address recipient
    ) external onlyRevertable(recipient) {
        _disputePeriod[recipient] = block.timestamp + DISPUTE_PERIOD;
    }

    function revertTransfer(
        address recipient
    ) external onlyRevertable(recipient) {
        if (_disputePeriod[recipient] == 0) {
            revert DisputePeriodNotSet();
        }
        if (block.timestamp < _disputePeriod[recipient]) {
            revert DisputePeriodNotOver();
        }

        uint revertValue = _transfers[msg.sender][recipient];
        _disputePeriod[recipient] = 0;
        _transfers[msg.sender][recipient] = 0;
        _transfer(recipient, msg.sender, revertValue);
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
