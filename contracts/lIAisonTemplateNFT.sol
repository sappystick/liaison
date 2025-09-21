// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title lIAisonTemplateNFT
 * @dev Simple NFT contract for chatbot template ownership and marketplace
 */
contract lIAisonTemplateNFT is ERC721URIStorage, ERC2981, Ownable, ReentrancyGuard {
    uint256 private _tokenIdCounter;
    
    // Template marketplace
    mapping(uint256 => uint256) public templatePrices;
    mapping(uint256 => bool) public templatesForSale;
    
    // Creator royalties (10%)
    uint96 public constant ROYALTY_FEE = 1000; // 10% in basis points
    
    event TemplateCreated(uint256 indexed tokenId, address indexed creator, string templateURI, uint256 price);
    event TemplateSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event TemplatePriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    
    constructor() ERC721("lIAison Template", "LIAT") {
        _setDefaultRoyalty(owner(), ROYALTY_FEE);
    }
    
    /**
     * @dev Create a new chatbot template NFT
     */
    function createTemplate(
        address creator,
        string memory templateURI,
        uint256 price
    ) external onlyOwner returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        _safeMint(creator, tokenId);
        _setTokenURI(tokenId, templateURI);
        
        if (price > 0) {
            templatePrices[tokenId] = price;
            templatesForSale[tokenId] = true;
        }
        
        emit TemplateCreated(tokenId, creator, templateURI, price);
        return tokenId;
    }
    
    /**
     * @dev Buy a template from the marketplace
     */
    function buyTemplate(uint256 tokenId) external payable nonReentrant {
        require(templatesForSale[tokenId], "Template not for sale");
        require(msg.value >= templatePrices[tokenId], "Insufficient payment");
        
        address seller = ownerOf(tokenId);
        uint256 price = templatePrices[tokenId];
        
        // Remove from sale
        templatesForSale[tokenId] = false;
        templatePrices[tokenId] = 0;
        
        // Transfer NFT
        _transfer(seller, msg.sender, tokenId);
        
        // Handle payment with royalty
        (address royaltyRecipient, uint256 royaltyAmount) = royaltyInfo(tokenId, price);
        
        if (royaltyAmount > 0 && royaltyRecipient != seller) {
            payable(royaltyRecipient).transfer(royaltyAmount);
            payable(seller).transfer(price - royaltyAmount);
        } else {
            payable(seller).transfer(price);
        }
        
        emit TemplateSold(tokenId, msg.sender, seller, price);
    }
    
    /**
     * @dev Set template for sale
     */
    function setTemplateForSale(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not template owner");
        require(price > 0, "Price must be greater than 0");
        
        templatePrices[tokenId] = price;
        templatesForSale[tokenId] = true;
        
        emit TemplatePriceUpdated(tokenId, price);
    }
    
    /**
     * @dev Remove template from sale
     */
    function removeFromSale(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not template owner");
        
        templatesForSale[tokenId] = false;
        templatePrices[tokenId] = 0;
        
        emit TemplatePriceUpdated(tokenId, 0);
    }
    
    /**
     * @dev Get all templates for sale
     */
    function getTemplatesForSale() external view returns (uint256[] memory) {
        uint256[] memory forSale = new uint256[](_tokenIdCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= _tokenIdCounter; i++) {
            if (templatesForSale[i]) {
                forSale[count] = i;
                count++;
            }
        }
        
        // Resize array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = forSale[i];
        }
        
        return result;
    }
    
    // Required overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}