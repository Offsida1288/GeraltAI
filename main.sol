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

    // -------------------------------------------------------------------------
    // ERRORS
    // -------------------------------------------------------------------------

    error GA_ZeroRequestId();
    error GA_NotOperator();
    error GA_ResponseAlreadySet();
    error GA_RequestAlreadySubmitted();
    error GA_MaxRequestsReached();
    error GA_InvalidIndex();
    error GA_ZeroAddress();

    // -------------------------------------------------------------------------
    // CONSTANTS
    // -------------------------------------------------------------------------

    uint256 public constant GA_MAX_REQUESTS = 50_000;
    bytes32 public constant GA_DOMAIN = keccak256("GeraltAI.GA_DOMAIN");

    // -------------------------------------------------------------------------
    // IMMUTABLES
    // -------------------------------------------------------------------------

    address public immutable operator;
    uint256 public immutable deployBlock;

    // -------------------------------------------------------------------------
    // STATE
    // -------------------------------------------------------------------------

    mapping(bytes32 => bytes32) private _responseOf;
    mapping(bytes32 => address) private _promptSenderOf;
    mapping(bytes32 => uint256) private _promptBlockOf;
    bytes32[] private _requestIds;
    uint256 public requestCount;

    // -------------------------------------------------------------------------
    // CONSTRUCTOR
    // -------------------------------------------------------------------------

    constructor() {
        operator = address(0x68e9F1a3B5c7D9e1F3a5B7c9d1E3f5A7b9C1d3e5);
        deployBlock = block.number;
        if (operator == address(0)) revert GA_ZeroAddress();
    }

    // -------------------------------------------------------------------------
    // MODIFIERS
    // -------------------------------------------------------------------------

    modifier onlyOperator() {
        if (msg.sender != operator) revert GA_NotOperator();
        _;
    }

    // -------------------------------------------------------------------------
    // PUBLIC: SUBMIT PROMPT (REQUEST)
    // -------------------------------------------------------------------------

    /// @notice Submit a prompt commitment; stores requestId and prompt hash. Does not require operator.
    function submitPrompt(bytes32 requestId, bytes32 promptHash) external {
        if (requestId == bytes32(0)) revert GA_ZeroRequestId();
        if (_promptBlockOf[requestId] != 0) revert GA_RequestAlreadySubmitted();
        if (requestCount >= GA_MAX_REQUESTS) revert GA_MaxRequestsReached();

        _promptSenderOf[requestId] = msg.sender;
        _promptBlockOf[requestId] = block.number;
        _requestIds.push(requestId);
        requestCount++;

        emit PromptSubmitted(msg.sender, requestId, promptHash, block.number);
    }

    // -------------------------------------------------------------------------
    // OPERATOR: SET RESPONSE
    // -------------------------------------------------------------------------

    /// @notice Set the response commitment for a request. Only operator (e.g. backend chatbot).
    function setResponse(bytes32 requestId, bytes32 responseHash) external onlyOperator {
        if (requestId == bytes32(0)) revert GA_ZeroRequestId();
        if (_responseOf[requestId] != bytes32(0)) revert GA_ResponseAlreadySet();

        _responseOf[requestId] = responseHash;
        emit ResponseSet(requestId, responseHash, block.number);
    }

    // -------------------------------------------------------------------------
    // VIEWS
    // -------------------------------------------------------------------------
