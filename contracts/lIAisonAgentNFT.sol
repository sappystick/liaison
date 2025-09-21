// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title lIAisonAgentNFT
 * @dev Revolutionary AI Agent NFT with Sacred Geometry, Breeding, and Professional Systems
 */
contract lIAisonAgentNFT is ERC721URIStorage, ERC2981, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    // Sacred Geometry Constants
    uint256 public constant GOLDEN_RATIO = 1618; // 1.618 * 1000 for precision
    uint256 public constant FIBONACCI_SCALE = 1000;
    
    // Professional Tiers
    enum ProfessionalTier { Basic, Professional, Expert, Elite }
    
    // Sacred Geometry Types
    enum GeometryType { 
        Tetrahedron,     // Security (4 faces)
        Hexahedron,      // Business (6 faces) 
        Octahedron,      // Creative (8 faces)
        Dodecahedron,    // Research (12 faces)
        Icosahedron      // Medical (20 faces)
    }
    
    // Agent Structure
    struct Agent {
        string name;
        GeometryType geometry;
        ProfessionalTier tier;
        uint256 generation;
        uint256 birthTimestamp;
        uint256 skillPoints;
        uint256 experienceLevel;
        address creator;
        bool isBreedable;
        uint256 breedingCooldown;
        uint256 lastBreedTime;
        uint256[] parentIds;
        string profession;
        uint256 hourlyRate; // in wei
    }
    
    // Breeding Structure
    struct BreedingRequest {
        uint256 parent1Id;
        uint256 parent2Id;
        address requester;
        uint256 timestamp;
        bool completed;
        uint256 resultTokenId;
    }
    
    // Professional Rates (in ETH wei)
    mapping(string => uint256) public professionalRates;
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => BreedingRequest) public breedingRequests;
    mapping(address => uint256[]) public ownerAgents;
    
    // Breeding configuration
    uint256 public breedingCost = 0.1 ether;
    uint256 public breedingCooldownPeriod = 7 days;
    uint256 public constant MAX_BREEDING_PER_AGENT = 5;
    
    // Royalty configuration
    uint96 public royaltyFeeNumerator = 500; // 5%
    
    // Events
    event AgentCreated(uint256 indexed tokenId, address indexed creator, string name, GeometryType geometry);
    event AgentBred(uint256 indexed parent1, uint256 indexed parent2, uint256 indexed offspring);
    event ProfessionalCertified(uint256 indexed tokenId, string profession, uint256 hourlyRate);
    event GeometryEvolved(uint256 indexed tokenId, GeometryType newGeometry);
    event SkillsUpgraded(uint256 indexed tokenId, uint256 newSkillPoints);
    
    constructor() ERC721("lIAison Agent", "LIAISON") {
        // Initialize professional rates
        professionalRates["AI Researcher"] = 0.35 ether;
        professionalRates["Medical Doctor"] = 0.30 ether;
        professionalRates["Security Expert"] = 0.25 ether;
        professionalRates["Legal Advisor"] = 0.28 ether;
        professionalRates["Data Scientist"] = 0.32 ether;
        professionalRates["Engineer"] = 0.22 ether;
        professionalRates["Creative Designer"] = 0.20 ether;
        professionalRates["Business Analyst"] = 0.15 ether;
        
        // Set default royalty
        _setDefaultRoyalty(owner(), royaltyFeeNumerator);
    }
    
    /**
     * @dev Create a new AI Agent with sacred geometry
     */
    function createAgent(
        string memory name,
        GeometryType geometry,
        string memory profession,
        string memory tokenURI
    ) external payable nonReentrant whenNotPaused {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(professionalRates[profession] > 0, "Invalid profession");
        
        uint256 creationCost = calculateCreationCost(geometry, profession);
        require(msg.value >= creationCost, "Insufficient payment");
        
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        // Create agent with sacred geometry attributes
        Agent memory newAgent = Agent({
            name: name,
            geometry: geometry,
            tier: ProfessionalTier.Basic,
            generation: 1,
            birthTimestamp: block.timestamp,
            skillPoints: calculateInitialSkills(geometry),
            experienceLevel: 0,
            creator: msg.sender,
            isBreedable: true,
            breedingCooldown: 0,
            lastBreedTime: 0,
            parentIds: new uint256[](0),
            profession: profession,
            hourlyRate: professionalRates[profession] / 10 // Start at 10% of professional rate
        });
        
        agents[tokenId] = newAgent;
        ownerAgents[msg.sender].push(tokenId);
        
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        emit AgentCreated(tokenId, msg.sender, name, geometry);
        emit ProfessionalCertified(tokenId, profession, newAgent.hourlyRate);
    }
    
    /**
     * @dev Breed two agents to create offspring with genetic algorithms
     */
    function breedAgents(uint256 parent1Id, uint256 parent2Id) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
        returns (uint256) 
    {
        require(msg.value >= breedingCost, "Insufficient breeding fee");
        require(_exists(parent1Id) && _exists(parent2Id), "Invalid parent IDs");
        require(parent1Id != parent2Id, "Cannot breed with itself");
        
        Agent storage parent1 = agents[parent1Id];
        Agent storage parent2 = agents[parent2Id];
        
        require(parent1.isBreedable && parent2.isBreedable, "Parents not breedable");
        require(
            block.timestamp >= parent1.lastBreedTime + breedingCooldownPeriod &&
            block.timestamp >= parent2.lastBreedTime + breedingCooldownPeriod,
            "Breeding cooldown active"
        );
        
        // Update breeding timestamps
        parent1.lastBreedTime = block.timestamp;
        parent2.lastBreedTime = block.timestamp;
        
        // Create offspring with genetic inheritance
        _tokenIdCounter.increment();
        uint256 offspringId = _tokenIdCounter.current();
        
        Agent memory offspring = _createOffspring(parent1, parent2, offspringId);
        agents[offspringId] = offspring;
        ownerAgents[msg.sender].push(offspringId);
        
        _safeMint(msg.sender, offspringId);
        
        emit AgentBred(parent1Id, parent2Id, offspringId);
        
        return offspringId;
    }
    
    /**
     * @dev Create offspring using genetic algorithms
     */
    function _createOffspring(Agent memory parent1, Agent memory parent2, uint256 tokenId) 
        private 
        view 
        returns (Agent memory) 
    {
        // Genetic inheritance with 70/30 probability distribution
        GeometryType inheritedGeometry = (block.timestamp % 10 < 7) ? parent1.geometry : parent2.geometry;
        
        // Calculate inherited traits
        uint256 inheritedSkills = (parent1.skillPoints + parent2.skillPoints) / 2;
        inheritedSkills += (inheritedSkills * (block.timestamp % 20)) / 100; // 0-20% bonus
        
        uint256 newGeneration = (parent1.generation > parent2.generation ? 
            parent1.generation : parent2.generation) + 1;
        
        // Create parent IDs array
        uint256[] memory parentIds = new uint256[](2);
        parentIds[0] = parent1.generation; // Use generation as proxy for ID in memory struct
        parentIds[1] = parent2.generation;
        
        return Agent({
            name: string(abi.encodePacked("Gen", _toString(newGeneration), "_Hybrid")),
            geometry: inheritedGeometry,
            tier: ProfessionalTier.Basic,
            generation: newGeneration,
            birthTimestamp: block.timestamp,
            skillPoints: inheritedSkills,
            experienceLevel: 0,
            creator: msg.sender,
            isBreedable: true,
            breedingCooldown: breedingCooldownPeriod,
            lastBreedTime: block.timestamp,
            parentIds: parentIds,
            profession: parent1.skillPoints > parent2.skillPoints ? parent1.profession : parent2.profession,
            hourlyRate: (parent1.hourlyRate + parent2.hourlyRate) / 2
        });
    }
    
    /**
     * @dev Calculate creation cost based on geometry and profession
     */
    function calculateCreationCost(GeometryType geometry, string memory profession) 
        public 
        view 
        returns (uint256) 
    {
        uint256 baseCost = 0.05 ether;
        uint256 geometryMultiplier = uint256(geometry) + 1;
        uint256 professionRate = professionalRates[profession];
        
        return baseCost * geometryMultiplier * professionRate / (1 ether);
    }
    
    /**
     * @dev Calculate initial skills based on sacred geometry
     */
    function calculateInitialSkills(GeometryType geometry) private pure returns (uint256) {
        uint256 faces = 4; // Tetrahedron default
        
        if (geometry == GeometryType.Hexahedron) faces = 6;
        else if (geometry == GeometryType.Octahedron) faces = 8;
        else if (geometry == GeometryType.Dodecahedron) faces = 12;
        else if (geometry == GeometryType.Icosahedron) faces = 20;
        
        return faces * GOLDEN_RATIO; // Sacred geometry skill calculation
    }
    
    /**
     * @dev Upgrade agent skills and potentially evolve geometry
     */
    function upgradeAgent(uint256 tokenId) external payable nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        Agent storage agent = agents[tokenId];
        uint256 upgradeCost = calculateUpgradeCost(tokenId);
        
        require(msg.value >= upgradeCost, "Insufficient upgrade fee");
        
        // Increase skills with Golden Ratio scaling
        agent.skillPoints = (agent.skillPoints * GOLDEN_RATIO) / FIBONACCI_SCALE;
        agent.experienceLevel++;
        
        // Potentially evolve geometry based on experience
        if (agent.experienceLevel % 5 == 0 && agent.experienceLevel > 0) {
            _evolveGeometry(tokenId);
        }
        
        // Upgrade professional tier
        if (agent.experienceLevel >= 10 && agent.tier == ProfessionalTier.Basic) {
            agent.tier = ProfessionalTier.Professional;
            agent.hourlyRate = (agent.hourlyRate * 150) / 100; // 50% increase
        } else if (agent.experienceLevel >= 25 && agent.tier == ProfessionalTier.Professional) {
            agent.tier = ProfessionalTier.Expert;
            agent.hourlyRate = (agent.hourlyRate * 200) / 100; // 100% increase
        } else if (agent.experienceLevel >= 50 && agent.tier == ProfessionalTier.Expert) {
            agent.tier = ProfessionalTier.Elite;
            agent.hourlyRate = (agent.hourlyRate * 300) / 100; // 200% increase
        }
        
        emit SkillsUpgraded(tokenId, agent.skillPoints);
    }
    
    /**
     * @dev Evolve agent geometry based on sacred mathematics
     */
    function _evolveGeometry(uint256 tokenId) private {
        Agent storage agent = agents[tokenId];
        
        // Evolution based on Platonic solid progression
        if (agent.geometry == GeometryType.Tetrahedron) {
            agent.geometry = GeometryType.Hexahedron;
        } else if (agent.geometry == GeometryType.Hexahedron) {
            agent.geometry = GeometryType.Octahedron;
        } else if (agent.geometry == GeometryType.Octahedron) {
            agent.geometry = GeometryType.Dodecahedron;
        } else if (agent.geometry == GeometryType.Dodecahedron) {
            agent.geometry = GeometryType.Icosahedron;
        }
        
        emit GeometryEvolved(tokenId, agent.geometry);
    }
    
    /**
     * @dev Calculate upgrade cost with exponential scaling
     */
    function calculateUpgradeCost(uint256 tokenId) public view returns (uint256) {
        Agent memory agent = agents[tokenId];
        uint256 baseCost = 0.01 ether;
        
        // Exponential cost increase
        return baseCost * (2 ** (agent.experienceLevel / 5));
    }
    
    /**
     * @dev Get agent details for frontend display
     */
    function getAgent(uint256 tokenId) external view returns (Agent memory) {
        require(_exists(tokenId), "Token does not exist");
        return agents[tokenId];
    }
    
    /**
     * @dev Get all agents owned by an address
     */
    function getOwnerAgents(address owner) external view returns (uint256[] memory) {
        return ownerAgents[owner];
    }
    
    /**
     * @dev Set professional rate for new professions
     */
    function setProfessionalRate(string memory profession, uint256 rate) external onlyOwner {
        professionalRates[profession] = rate;
    }
    
    /**
     * @dev Update breeding cost
     */
    function setBreedingCost(uint256 newCost) external onlyOwner {
        breedingCost = newCost;
    }
    
    /**
     * @dev emergency pause functionality
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Withdraw contract funds
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @dev Convert uint256 to string
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    // Required overrides for multiple inheritance
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}