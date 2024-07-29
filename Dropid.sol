// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "./_pausable.sol";
import "./_event.sol";
import "./_error.sol";
import "./_lib.sol";

/// @title Dropid 🆔
/// @author Aratta Labs
/// @notice Dropid on ⏣ LUKSO
/// @dev You can find deployed contract addresses in the README.md file
/// @custom:security-contact atenyun@gmail.com
contract Dropid is LSP8IdentifiableDigitalAsset("Dropid", "DID", msg.sender, 2, 0), Pausable {
    using Counters for Counters.Counter;

    Counters.Counter public _recordTypeCounter;
    Counters.Counter public _resolveCounter;
    Counters.Counter private _tokenIds;

    uint8 minimumLength = 3;

    struct RecordTypeStruct {
        string name;
        uint256 price;
        string[] reserved;
        string metadata;
        uint256 dt;
        address manager;
        uint8 percentage;
        bool pause;
    }

    struct ResolveStruct {
        bytes32 recordTypeId;
        bytes32 tokenId;
        bytes32 nodehash;
        string metadata;
        address manager;
        uint256 exp;
    }

    struct NameListStruct {
        bytes32 id;
        string name;
        uint256 price;
        uint8 percentage;
        address manager;
    }

    mapping(bytes32 => RecordTypeStruct) public recordType;
    mapping(bytes32 => ResolveStruct) public resolve;
    mapping(bytes32 => mapping(bytes32 => string)) public blockStorage;

    ///@dev Throws if called by any account other than the manager
    modifier onlyManager(bytes32 nodehash) {
        uint256 resolveIndex = _indexOfResolve(nodehash);
        require(resolve[bytes32(resolveIndex)].manager == _msgSender() || _msgSender() == owner(), "The sender is not the manager of the entered nodehash.");
        _;
    }

    constructor() {
        string[] memory reserved = new string[](1);
        reserved[0] = "amir";

        // Add LUKSO = 0x0000000000000000000000000000000000000000000000000000000000000001
        _recordTypeCounter.increment();
        recordType[bytes32(_recordTypeCounter.current())] = RecordTypeStruct(toLower("lukso"), 2.14 ether, reserved, "", block.timestamp, _msgSender(), 0, false);
        emit RecordTypeAdded(bytes32(_recordTypeCounter.current()), toLower("lukso"));

        // Add LYX
        _recordTypeCounter.increment();
        recordType[bytes32(_recordTypeCounter.current())] = RecordTypeStruct(toLower("lyx"), 1 ether, reserved, "", block.timestamp, _msgSender(), 0, false);
        emit RecordTypeAdded(bytes32(_recordTypeCounter.current()), toLower("lyx"));

        // Add 🆙
        _recordTypeCounter.increment();
        recordType[bytes32(_recordTypeCounter.current())] = RecordTypeStruct(toLower(unicode"🆙"), 0.5 ether, reserved, "", block.timestamp, _msgSender(), 0, false);
        emit RecordTypeAdded(bytes32(_recordTypeCounter.current()), toLower(unicode"🆙"));

        // Add ☕
        _recordTypeCounter.increment();
        recordType[bytes32(_recordTypeCounter.current())] = RecordTypeStruct(toLower(unicode"☕"), 0.25 ether, reserved, "", block.timestamp, _msgSender(), 0, false);
        emit RecordTypeAdded(bytes32(_recordTypeCounter.current()), toLower(unicode"☕"));
    }

    function getMetadata(bytes memory _rawMetadata) public pure returns (bytes memory) {
        bytes memory verfiableURI = bytes.concat(hex"00006f357c6a0020", keccak256(_rawMetadata), abi.encodePacked("data:application/json;base64,", Base64.encode(_rawMetadata)));
        return verfiableURI;
    }

    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory lowerCaseStr = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Convert uppercase characters to lowercase
            if (uint8(bStr[i]) >= 65 && uint8(bStr[i]) <= 90) {
                lowerCaseStr[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                lowerCaseStr[i] = bStr[i];
            }
        }
        return string(lowerCaseStr);
    }

    function toLowercase(string memory _arg) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_arg)) >> 32;
    }

    /// @notice Store a new key/ value
    function setKey(
        bytes32 appId,
        bytes32 key,
        string memory val
    ) public onlyOwner {
        blockStorage[appId][key] = val;
    }

    /// @notice Get the stored value
    /// @param appId The bytes32 ID
    /// @param key A byte32 key
    /// @return value in CID format
    function getKey(bytes32 appId, bytes32 key) public view returns (string memory) {
        return blockStorage[appId][key];
    }

    /// @notice Delete a key from the storage
    /// @param appId The bytes32 ID
    /// @param key A byte32 key
    /// @return boolean
    function delKey(bytes32 appId, bytes32 key) public onlyOwner returns (bool) {
        delete blockStorage[appId][key];
        return true;
    }

    /// @notice Update default Metadata
    // function updateDefaultMetadata(string memory metadata) public onlyOwner {
    //     defaultMetadata = metadata;
    // }

    function addRecordType(
        string memory _name,
        uint256 _price,
        string[] memory _reserved,
        string memory _metadata,
        address _manager,
        uint8 _percentage,
        bool _pause
    ) public onlyOwner {
        _recordTypeCounter.increment();
        recordType[bytes32(_recordTypeCounter.current())] = RecordTypeStruct(toLower(_name), _price, _reserved, _metadata, block.timestamp, _manager, _percentage, _pause);
        emit RecordTypeAdded(bytes32(_recordTypeCounter.current()), toLower(_name));
    }

    /// @notice Update record type
    function updateRecordType(
        bytes32 _recordTypeId,
        string memory _name,
        uint256 _price,
        string[] memory _reserved,
        string memory _metadata,
        address _manager,
        uint8 _percentage,
        bool _pause
    ) public onlyOwner {
        recordType[_recordTypeId].name = toLower(_name);
        recordType[_recordTypeId].price = _price;
        recordType[_recordTypeId].reserved = _reserved;
        recordType[_recordTypeId].metadata = _metadata;
        recordType[_recordTypeId].manager = _manager;
        recordType[_recordTypeId].percentage = _percentage;
        recordType[_recordTypeId].pause = _pause;
        emit RecordTypeUpdated(bytes32(_recordTypeCounter.current()), toLower(_name));
    }

    function getRecordTypeNameList() public view returns (NameListStruct[] memory) {
        uint256 totalRecordType = _recordTypeCounter.current();
        NameListStruct[] memory result = new NameListStruct[](totalRecordType);

        for (uint256 i = 0; i < totalRecordType; i++) {
            result[i] = NameListStruct(bytes32(i + 1), recordType[bytes32(i + 1)].name, recordType[bytes32(i + 1)].price, recordType[bytes32(i + 1)].percentage, recordType[bytes32(i + 1)].manager);
        }

        return result;
    }

    function getResolveList(address _manager) public view returns (ResolveStruct[] memory list) {
        ResolveStruct[] memory result = new ResolveStruct[](_resolveCounter.current());

        uint256 counter = 0;
        for (uint256 i = 1; i <= _resolveCounter.current(); i++) {
            if (resolve[bytes32(i)].manager == _manager) {
                result[counter] = resolve[bytes32(i)];
                counter++;
            }
        }

        return result;
    }

    function getResolveListByRecordType(bytes32 _recordTypeId) public view returns (ResolveStruct[] memory list) {
        ResolveStruct[] memory result = new ResolveStruct[](_resolveCounter.current());

        uint256 counter = 0;
        for (uint256 i = 1; i <= _resolveCounter.current(); i++) {
            if (resolve[bytes32(i)].recordTypeId == _recordTypeId) {
                result[counter] = resolve[bytes32(i)];
                counter++;
            }
        }

        return result;
    }

    function toNodehash(string memory _name, bytes32 _recordTypeId) public view returns (bytes32) {
        bytes32 nodehash;
        return nodehash = bytes32(keccak256(bytes.concat(bytes(toLower(_name)), bytes("."), bytes(recordType[_recordTypeId].name))));
    }

    ///@notice Calculate percentage
    ///@param amount The total amount
    ///@param bps The precentage
    ///@return percentage
    function calcPercentage(uint256 amount, uint256 bps) public pure returns (uint256) {
        require((amount * bps) >= 100);
        return (amount * bps) / 100;
    }

    // Check if the name is duplicated if it's not expired
    function _freeToRegister(bytes32 _nodehash) public view returns (bool) {
        for (uint256 i = 0; i < _resolveCounter.current(); i++) if (resolve[bytes32(i + 1)].nodehash == _nodehash) return true;
        return false;
    }

    function checkRecordTypeId(bytes32 _recordTypeId) public view returns (bool) {
        uint256 totalRecordType = _recordTypeCounter.current();
        for (uint256 i = 1; i <= totalRecordType; i++) if (bytes32(i) == _recordTypeId) return true;
        return false;
    }

    function register(
        string memory _name,
        bytes32 _recordTypeId,
        bytes memory _rawMetadata
    ) public payable whenNotPaused returns (bytes32, uint256) {
        // Check the recordTypeId
        require(checkRecordTypeId(_recordTypeId), "The provided recordTypeId is invalid.");

        // Check price and length
        if (_msgSender() != owner()) {
            // Check length
            require(bytes(_name).length > 2, "A name must be a minimum of 2 characters long.");
            // Check price
            if (msg.value < recordType[_recordTypeId].price) revert InsufficientBalance(recordType[_recordTypeId].price, msg.value);
        }

        // Check if the name is duplicated if it's not expired
        bytes32 nodehash = bytes32(keccak256(bytes.concat(bytes(toLower(_name)), bytes("."), bytes(recordType[_recordTypeId].name))));

        require(!_freeToRegister(nodehash), "The name you are trying to register is already registered.");

        // Check if the recordType manager is not the owner
        if (recordType[_recordTypeId].manager != owner()) {
            uint256 amount = calcPercentage(msg.value, recordType[_recordTypeId].percentage);
            (bool success, ) = recordType[_recordTypeId].manager.call{value: amount}("");
            require(success, "Failed to send Ether to the manager");
        }

        // Mint NFT
        _tokenIds.increment();
        bytes32 _tokenId = bytes32(_tokenIds.current());
        _mint({to: _msgSender(), tokenId: _tokenId, force: true, data: ""});
        // Set metadata
        _setDataForTokenId(bytes32(_tokenIds.current()), 0x9afb95cacc9f95858ec44aa8c3b685511002e30ae54415823f406128b85b238e, getMetadata(_rawMetadata));

        // Buy it
        _resolveCounter.increment();
        resolve[bytes32(_resolveCounter.current())] = ResolveStruct(_recordTypeId, _tokenId, nodehash, "", _msgSender(), (block.timestamp + 365 days));
        emit newDomain(nodehash);

        return (nodehash, _tokenIds.current());
    }

    /// @notice Update URL
    /// onlyManager(_nodehash)
    function updateResolve(
        bytes32 _nodehash,
        address _manager,
        string memory _metadata,
        bytes memory _rawMetadata
    ) public {
        // check if the token id of the nodehash is the sender, so users can trade the nfts/ domains
        bytes32 _resolveId = bytes32(_indexOfResolve(_nodehash));
        resolve[_resolveId].manager = _manager;
        resolve[_resolveId].metadata = _metadata;

        require(tokenOwnerOf(resolve[_resolveId].tokenId) == owner(), "Sender is not the owner of entred username.");

        // Set LSP8 metadata
        _setDataForTokenId(bytes32(_resolveId), 0x9afb95cacc9f95858ec44aa8c3b685511002e30ae54415823f406128b85b238e, getMetadata(_rawMetadata));

        emit ResolveUpdated(_manager, _metadata);
    }

    /// everyone can renewal a domain
    function renewal(bytes32 _nodehash) public payable returns (bool) {
        // Get resolve index
        uint256 _resolveIndex = _indexOfResolve(_nodehash);
        bytes32 _recordTypeId = resolve[bytes32(_resolveIndex)].recordTypeId;

        // Check the amount
        /// owner can renew a domain without spending $
        if (_msgSender() != owner()) {
            if (msg.value < recordType[_recordTypeId].price) revert InsufficientBalance(recordType[_recordTypeId].price, msg.value);
        }

        // Check if the recordType manager is not the owner
        if (recordType[_recordTypeId].manager != owner()) {
            uint256 amount = calcPercentage(msg.value, recordType[_recordTypeId].percentage);
            (bool success, ) = recordType[_recordTypeId].manager.call{value: amount}("");
            require(success, "Failed to send Ether to the manager");
        }

        // update the expiration, a year
        resolve[bytes32(_resolveIndex)] = ResolveStruct(_recordTypeId, resolve[bytes32(_resolveIndex)].tokenId, resolve[bytes32(_resolveIndex)].nodehash, resolve[bytes32(_resolveIndex)].metadata, resolve[bytes32(_resolveIndex)].manager, (block.timestamp + 360 days));

        emit RenewalResolve(_nodehash);

        return true;
    }

    function _indexOfResolve(bytes32 _nodehash) internal view returns (uint256) {
        for (uint256 i = 0; i < _resolveCounter.current(); i++) if (resolve[bytes32(i + 1)].nodehash == _nodehash) return i + 1;
        revert("Resolve Not Found");
    }

    function resolver(bytes32 _nodehash) public view returns (ResolveStruct memory) {
        for (uint256 i = 1; i <= _resolveCounter.current(); i++)
            if (resolve[bytes32(i)].nodehash == _nodehash) {
                // Check if the domain isn't expired
                if (block.timestamp < resolve[bytes32(i)].exp) return resolve[bytes32(i)];
            }
        revert Reverted();
    }

    /// Domains tidy up by any users!
    function removeExpiredResolve() public {
        for (uint256 i = 1; i <= _resolveCounter.current(); i++)
            // Check whether the domain has expired.
            if (block.timestamp > resolve[bytes32(i)].exp) {
                bytes32 tokenId = resolve[bytes32(i)].tokenId;
                _burn(tokenId, "");
                delete resolve[bytes32(i)];
            }
    }

    function removeResolveByNodehash(bytes32 _nodehash) public onlyOwner {
        uint256 _resolveIndex = _indexOfResolve(_nodehash);
        bytes32 tokenId = resolve[bytes32(_resolveIndex)].tokenId;
        _burn(tokenId, "");
        delete resolve[bytes32(_resolveIndex)];
    }

    function removeResolveByIndex(bytes32 _resolveIndex) public onlyOwner {
        bytes32 tokenId = resolve[_resolveIndex].tokenId;
        _burn(tokenId, "");
        delete resolve[_resolveIndex];
    }

    function updateMinimumLength(uint8 _len) public onlyOwner {
        minimumLength = _len;
        emit MinimumLengthUpdated(_len);
    }

    ///@notice Withdraw the balance from this contract and transfer it to the owner's address
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed");
    }

    ///@notice Transfer balance from this contract to input address
    function transferBalance(address payable _to, uint256 _amount) public onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed");
    }

    /// @notice Return the balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Pause mint
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause mint
    function unpause() public onlyOwner {
        _unpause();
    }
}
