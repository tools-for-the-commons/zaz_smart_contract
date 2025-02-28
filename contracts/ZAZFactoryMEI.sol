// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ZAZFactoryMei is ERC721URIStorage, ReentrancyGuard, Ownable {
    using Address for address;

    uint256 private _tokenIdCounter;
    mapping(uint256 => Company) public companies;
    mapping(address => uint256) public tokenToCompany;
    mapping(uint256 => Certificate) public certificates;  // Stores certificates linked to company IDs
    address[] public companyAddresses;

    struct Company {
        string name;
        string description;
        string documents;
        address tokenOwner; // Address of the token contract (ERC-20 or ERC-721)
    }

    struct Certificate {
        string certificateUrl;  // Link to the certificate (can be a JSON file or IPFS link)
        string issueDate;       // Date of issuance
        string validation;      // Additional information about validity or status
    }

    event CompanyCreated(address indexed tokenOwner, uint256 companyId, string name);
    event CertificateIssued(uint256 indexed companyId, string certificateUrl);
    event CertificateUpdated(uint256 indexed companyId, string certificateUrl);

    constructor() ERC721("CompanyToken", "COMP") {}

    // Create a company linked to a token contract (ERC-20 or ERC-721)
    function createCompany(
        string memory _name,
        string memory _description,
        string memory _documents,
        address _tokenOwner, // Token contract address (ERC-20 or ERC-721)
        string memory _tokenURI
    ) external nonReentrant {
        require(bytes(_name).length > 0, "Company name cannot be empty");
        require(_tokenOwner != address(0), "Invalid token address");
        require(tokenToCompany[_tokenOwner] == 0, "This token already has a registered company");

        // Creating a unique company ID
        _tokenIdCounter++;
        uint256 newCompanyId = _tokenIdCounter;

        companies[newCompanyId] = Company({
            name: _name,
            description: _description,
            documents: _documents,
            tokenOwner: _tokenOwner // The token contract will be the "owner"
        });

        tokenToCompany[_tokenOwner] = newCompanyId;
        companyAddresses.push(_tokenOwner);

        // Mint the token and set the URI
        _mint(_tokenOwner, newCompanyId);
        _setTokenURI(newCompanyId, _tokenURI);

        emit CompanyCreated(_tokenOwner, newCompanyId, _name);
    }

    // Issues or updates a certificate for the company
    function issueCertificate(
        uint256 _companyId, 
        string memory _certificateUrl, 
        string memory _issueDate,
        string memory _validation
    ) external nonReentrant {
        require(_exists(_companyId), "Company does not exist");
        Company storage company = companies[_companyId];

        // Verifies if the one issuing the certificate is the owner of the company (tokenOwner)
        require(msg.sender == company.tokenOwner, "Only the company owner can issue or update the certificate");

        // If a certificate already exists, the event will be an update
        if (bytes(certificates[_companyId].certificateUrl).length > 0) {
            emit CertificateUpdated(_companyId, _certificateUrl);
        } else {
            emit CertificateIssued(_companyId, _certificateUrl);
        }

        certificates[_companyId] = Certificate({
            certificateUrl: _certificateUrl,
            issueDate: _issueDate,
            validation: _validation
        });
    }

    // Returns the certificate of a company
    function getCertificate(uint256 _companyId) external view returns (string memory certificateUrl, string memory issueDate, string memory validation) {
        require(_exists(_companyId), "Company does not exist");

        Certificate storage certificate = certificates[_companyId];

        return (certificate.certificateUrl, certificate.issueDate, certificate.validation);
    }

    // Returns the owner of the token linked to the company
    function getCompanyOwner(uint256 companyId) external view returns (address) {
        require(_exists(companyId), "Company does not exist");
        return companies[companyId].tokenOwner;
    }

    // Checks who the true owner of the company is (if it's an NFT)
    function trueOwner(uint256 companyId) public view returns (address) {
        require(_exists(companyId), "Company does not exist");
        Company storage company = companies[companyId];

        // If it's an NFT, checks who owns this token
        try IERC721(company.tokenOwner).ownerOf(1) returns (address owner) {
            return owner;
        } catch {
            return company.tokenOwner;
        }
    }

    // Modifier to ensure that only the company owner can execute sensitive functions
    modifier onlyCompanyOwner(uint256 companyId) {
        require(msg.sender == companies[companyId].tokenOwner, "Only the token owner can execute this function");
        _;
    }
}
