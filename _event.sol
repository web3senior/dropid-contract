// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

event newDomain(bytes32 node);
event RenewalResolve(bytes32 node);
event Log(string func, uint256 gas);
event NewExtension(bytes32 id);
event RecordTypeAdded(bytes32 indexed id, string name);
event RecordTypeUpdated(bytes32 indexed id, string name);
event ResolveUpdated(address indexed manager, string metadata);
event MinimumLengthUpdated(uint8 metadata);