// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title GeraltAI
/// @notice On-chain response ledger for a chatbot: operator posts response commitments for request ids; anyone can submit a prompt hash and later read the stored response. Suited for verifiable Q&A or agent logs.
/// @dev Operator is immutable; no ETH held. Remix: compile 0.8.20+, deploy with no args.

contract GeraltAI {

    // -------------------------------------------------------------------------
    // EVENTS
    // -------------------------------------------------------------------------

    event PromptSubmitted(address indexed user, bytes32 requestId, bytes32 promptHash, uint256 atBlock);
    event ResponseSet(bytes32 indexed requestId, bytes32 responseHash, uint256 atBlock);
