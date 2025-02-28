// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ZAZBusinessPartnerToken is ERC721URIStorage {
    uint256 private currentTokenId;
    
    event CreateAPartner(address indexed to, uint256 token);

    constructor() ERC721("Business Partner Token", "BPT") {}

    function mintPartnerToken(address to, string memory tokenURI) external returns(uint) {
        require(to != address(0), "Invalid address");
        currentTokenId ++;
        _mint(to, currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);

        emit CreateAPartner(to, currentTokenId);

        return currentTokenId;
    }

    function getTokenURI(uint256 tokenId) external view returns(string memory) {
        return tokenURI(tokenId);
    }

}