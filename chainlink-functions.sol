// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FunctionsClient} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.3.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.3.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract GettingStartedFunctionsConsumer is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(
        bytes32 indexed requestId,
        string character,
        bytes response,
        bytes err
    );

    uint32 gasLimit = 300000;

    // Router address - Hardcoded for Base Sepolia
    address router = 0xf9B8fc078197181C841c296C876945aaa425B278;
    bytes32 donID =
        0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000;

    constructor() FunctionsClient(router) {}

    string source = "return Functions.encodeString(data.name);";
    string public character;

    // This function is not mandatory, the internal logic of this function can be used in other functions
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args
    ) external returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args);

        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    // this Function is mandatory in the smart contract, this function will be called by the chainlink DON through handleOracleFulfillment function
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        s_lastResponse = response;
        character = string(response);
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, character, s_lastResponse, s_lastError);
    }
}
