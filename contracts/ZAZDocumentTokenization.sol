// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ICompanyRegistry {
    function isValidCompany(address company) external view returns (bool);
}

contract ZAZDocumentTokenization is ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    uint256 private _tokenIds;
    mapping(string => bool) private documentExists;
    mapping(uint256 => bool) private documentActive;
    mapping(uint256 => address) private documentToCompany;
    ICompanyRegistry private companyRegistry;

    event DocumentTokenized(address indexed owner, uint256 tokenId, string documentHash, address companyAddress);
    event DocumentStatusUpdated(uint256 tokenId, bool isActive);

    constructor(address _companyRegistry) ERC721("DocumentToken", "DOC") {
        require(_companyRegistry != address(0), "Invalid registry address");
        companyRegistry = ICompanyRegistry(_companyRegistry);
    }

    function tokenizeDocument(string memory documentHash, string memory metadataURI, address companyAddress) public onlyOwner returns (uint256) {
        require(!documentExists[documentHash], "Document already tokenized");
        require(companyAddress != address(0), "Invalid company address");
        require(companyRegistry.isValidCompany(companyAddress), "Company is not registered");
        
        documentExists[documentHash] = true;
        _tokenIds = _tokenIds.add(1);
        uint256 newTokenId = _tokenIds;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, metadataURI);
        documentActive[newTokenId] = true;
        documentToCompany[newTokenId] = companyAddress;

        emit DocumentTokenized(msg.sender, newTokenId, documentHash, companyAddress);
        
        return newTokenId;
    }

    function setDocumentStatus(uint256 tokenId, bool isActive) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        documentActive[tokenId] = isActive;
        emit DocumentStatusUpdated(tokenId, isActive);
    }

    function isDocumentActive(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return documentActive[tokenId];
    }

    function getDocumentCompany(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return documentToCompany[tokenId];
    }
}
