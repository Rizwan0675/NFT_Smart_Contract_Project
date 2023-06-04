// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RizNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Pausable, Ownable {



 ////////////////////////////////////////////////////////// Structs //////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Represents a normal user.
     * @param userName The name of the user.
     * @param userAddress The address of the user.
     * @param userGlobalLimit The global minting limit for the user.
     * @param userRole The role of the user.
     * @param isUserRegistered A flag indicating if the user is registered.
     */
    struct normalUsers
    {
        string userName;
        address userAddress;
        uint userGlobalLimit;
        string userRole;
        bool isUserRegistered;
        
    }

    /**
     * @dev Represents a premium user.
     * @param userName The name of the user.
     * @param userAddress The address of the user.
     * @param userGlobalLimit The global minting limit for the user.
     * @param userRole The role of the user.
     * @param isUserRegistered A flag indicating if the user is registered.
     * @param isUserVerified A flag indicating if the user is verified.
     */
    struct premiumUsers
    {
        string userName;
        address userAddress;
        uint userGlobalLimit;
        string userRole;
        bool isUserRegistered;
        bool isUserVerified;
    }

    /**
     * @dev Represents an admin user.
     * @param userName The name of the admin user.
     * @param userAddress The address of the admin user.
     * @param userRole The role of the admin user.
     * @param isUserRegistered A flag indicating if the admin user is registered.
     */
    struct Admins{
        string userName;
        address userAddress;
        string userRole;
        bool isUserRegistered;
    }

    /**
     * @dev Represents the details of a phase.
     * @param reservedLimit The reserved limit for the phase.
     * @param premiumUserLimit The minting limit for premium users in the phase.
     * @param normalUserLimit The minting limit for normal users in the phase.
     * @param premiumUserBalance Mapping to track the minting balance of premium users in the phase.
     * @param normalUserBalance Mapping to track the minting balance of normal users in the phase.
     * @param isActive A flag indicating if the phase is active.
     * @param isCreated A flag indicating if the phase is created.
     */
    struct PhaseDetails {
        uint reservedLimit;
        uint premiumUserLimit;
        uint normalUserLimit;
        mapping(address => uint256) premiumUserBalance;
        mapping(address => uint256) normalUserBalance;
        bool isActive;
        bool isCreated;
    }


    /**
     * @dev Represents the data for bulk NFT minting.
     * @param tokenId The identifier of the bulk NFT data.
     * @param tokenUri The URI of the bulk NFT data.
     */
    struct BulkNFTData{
        uint tokenId;
        string tokenUri;
    }


 ////////////////////////////////////////////////////////// Mappings //////////////////////////////////////////////////////////////////////////////////////

     /**
     * @dev Maps an address to a premium user struct.
     * This mapping stores the premium user details based on their address.
     */
    mapping (address => premiumUsers) public PremiumUsersMapping;

    /**
     * @dev Maps an address to a normal user struct.
     * This mapping stores the normal user details based on their address.
     */
    mapping (address => normalUsers) public NormalUsersMApping;

    /**
     * @dev Maps an address to an admin struct.
     * This mapping stores the admin details based on their address.
     */
    mapping (address => Admins) public AdminsMapping;

    /**
     * @dev Maps a phase ID to a phase details struct.
     * This mapping stores the details of each phase based on their ID.
     */
    mapping(uint256 => PhaseDetails) public phasesMapping;
    

 ////////////////////////////////////////////////////////// Modifier & Custom Errors //////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Modifier to check if the current phase is active.
     * It ensures that the function can only be executed when the current phase is active.
     * Throws an error if the current phase is not active.
     */
    modifier onlyActivePhase() {
        require(phasesMapping[currentPhase].isActive, "Phase is not active");
        _;
    }




    /**
     * @dev Custom errors:
     * 1. To log error when an Invalid Role in entered by owner in RegisterUser function.
     * 2. To log error when user is neither normal nor premium in the update globaluserlimit function.
     */
    error InvalidRole_UserRegistrationFailed();
    error Neither_Normal_nor_Premium_User();


 ////////////////////////////////////////////////////////// Events //////////////////////////////////////////////////////////////////////////////////////


    /**
     * @dev Event triggered when a user is registered.
     * @param name The name of the registered user.
     * @param userAddress The address of the registered user.
     * @param role The role of the registered user.
     * @notice This event is emitted when a user successfully registers.
     * @notice It provides information about the registered user's name, address, and role.
     */
    event UserRegistered(string name, address userAddress, string role);


    /**
     * @dev Event triggered when a user's premium status is verified.
     * @param name The name of the verified user.
     * @param userAddress The address of the verified user.
     * @notice This event is emitted when a user's premium status is successfully verified.
     * @notice It provides information about the verified user's name and address.
     */
    event PremiumVerified(string name, address userAddress);


    /**
     * @dev Event triggered when a phase is created.
     * @param Description The description of the created phase.
     * @param phaseId The ID of the created phase.
     * @param phaseReservedLimit The reserved limit set for the created phase.
     * @notice This event is emitted when a phase is successfully created.
     * @notice It provides information about the description, ID, and reserved limit of the created phase.
     */
    event PhaseCreated(string Description, uint phaseId, uint phaseReservedLimit);

    /**
     * @dev Event triggered when a phase is activated.
     * @param Description The description of the activated phase.
     * @param phaseId The ID of the activated phase.
     * @param time The timestamp when the phase was activated.
     * @notice This event is emitted when a phase is successfully activated.
     * @notice It provides information about the activated phase's description, ID, and activation time.
     */
    event PhaseActivated(string Description, uint phaseId, uint time);

    /**
     * @dev Event triggered when a phase is deactivated.
     * @param Description The description of the deactivated phase.
     * @param phaseId The ID of the deactivated phase.
     * @param time The timestamp when the phase was deactivated.
     * @notice This event is emitted when a phase is successfully deactivated.
     * @notice It provides information about the deactivated phase's description, ID, and deactivation time.
     */
    event PhaseDeActivated(string Description, uint phaseId, uint time);


    /**
     * @dev Event triggered when the reserve limit is updated.
     * @param Description The description of the reserve limit update.
     * @param newAmount The new reserve limit amount.
     * @param time The timestamp when the reserve limit was updated.
     * @notice This event is emitted when the reserve limit is successfully updated.
     * @notice It provides information about the description of the update, the new reserve limit amount, and the update time.
     */
    event ReserveLimitUpdated(string Description, uint newAmount, uint time);


    /**
     * @dev Event triggered when the global limit is updated for a specific user.
     * @param Description The description of the global limit update.
     * @param userAddress The address of the user for whom the global limit is updated.
     * @param newAmount The new global limit amount.
     * @param time The timestamp when the global limit was updated.
     * @notice This event is emitted when the global limit is successfully updated for a user.
     * @notice It provides information about the description of the update, the user's address, the new global limit amount, and the update time.
     */
    event GlobalLimitUpdated(string Description, address userAddress, uint newAmount, uint time);

    /**
     * @dev Event triggered when the bulk hashes are updated for a token.
     * @param tokenId The ID of the token for which the bulk hashes are updated.
     * @param tokenUri The updated URI of the token.
     * @param isUpdated Boolean value indicating whether the bulk hashes are successfully updated.
     * @notice This event is emitted when the bulk hashes are successfully updated for a token.
     * @notice It provides information about the token ID, the updated URI, and whether the update is successful.
     */
    event BulkHashesUpdated(uint tokenId, string tokenUri, bool isUpdated);

    /**
     * @dev Event triggered when an NFT is fetched by address.
     * @param Description The description of the NFT fetch event.
     * @param userAddress The address of the user who holds the NFT.
     * @param tokenId The ID of the fetched NFT.
     * @param tokenUri The URI of the fetched NFT.
     * @notice This event is emitted when an NFT is successfully fetched by address.
     * @notice It provides information about the event description, the user's address, the token ID, and the token URI.
     */
    event NftFetchedByAddress(string Description, address userAddress, uint tokenId, string tokenUri);




 ////////////////////////////////////////////////////////// State Variables //////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Maximum minting limit for NFTs in the whole contract.
     */
    uint public maxMintLimit;

    /**
     * @dev Platform minting limit for NFTs.
     * Only applicable to admin addresses.
     */
    uint public platformMintLimit;

    /**
     * @dev User minting limit for NFTs.
     */
    uint public usersMintLimit;

    /**
     * @dev Remaining User minting limit after each mint for NFTs.
     */
    uint public usersMintedBalance;

    /**
     * @dev Current phase identifier.
     * Represents the index of the current phase in the phases mapping.
     */
    uint256 public currentPhase;

    /**
     * @dev ReservedLimit of current phase checker.
     * Represents the amount of the reservedlimit of currentphase.
     */
    uint256 public reservedLimitCurrentPhase;

    /**
     * @dev Flag indicating whether _transfer function status is transferable or not.
     */
    bool isTransferable;


    /**
     * @dev Contract constructor.
     * @param _maxMintLimit The maximum minting limit for NFTs.
     * @param _platformMintLimit The platform minting limit for NFTs.
     * The platform minting limit is subtracted from the maximum minting limit to calculate the user minting limit.
     */
    constructor(uint _maxMintLimit, uint _platformMintLimit) ERC721("RizNFT", "RFT")
    {
        maxMintLimit = _maxMintLimit;
        platformMintLimit = _platformMintLimit;
        usersMintLimit = maxMintLimit - platformMintLimit;
    }



 ////////////////////////////////////////////////////////// Functions //////////////////////////////////////////////////////////////////////////////////////


    /**
     * @dev Register users with their details and assign roles.
     * Only the contract owner can register users.
     * @param _userName The name of the user.
     * @param _userAddress The address of the user.
     * @param _userGlobalLimit The global limit for minting NFTs by the user.
     * @param _userRole The role of the user.
     * Must be one of the following: "PremiumUser", "premiumUser", "NormalUser", "normalUser", "Admin", "admin".
     * Depending on the role, the user will be added to the corresponding mapping.
     * @notice The user address must not be a zero address.
     * @notice The user address must not be already registered as a premium user, normal user, or admin.
     * @notice If the user role is not recognized, the user registration will fail.
     */
    function RegisterUsers
    (
        string memory _userName,
        address _userAddress,
        uint _userGlobalLimit,
        string memory _userRole
    )
    public onlyOwner whenNotPaused
    {
        require(_userAddress != address(0), "Invalid address");
        require(PremiumUsersMapping[_userAddress].userAddress == address(0) &&
                NormalUsersMApping[_userAddress].userAddress == address(0)  &&
                AdminsMapping[_userAddress].userAddress == address(0), "User with provided address is already Registered.");
        

        if(
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("Premium"))
        ||
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("premium"))
        ||
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("PREMIUM")))
        {
            PremiumUsersMapping[_userAddress] = premiumUsers(_userName, _userAddress, _userGlobalLimit, _userRole, true, false);
            emit UserRegistered(_userName, _userAddress, _userRole);
            
        }

        else if(
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("Normal"))
        ||
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("normal"))
        ||
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("NORMAL")))
        {
            NormalUsersMApping[_userAddress] = normalUsers(_userName, _userAddress, _userGlobalLimit, _userRole, true);
            emit UserRegistered(_userName, _userAddress, _userRole);
        }

        else if(
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("Admin"))
        ||
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("admin"))
        ||
        keccak256(abi.encodePacked(_userRole)) == keccak256(abi.encodePacked("ADMIN")))
        {
            AdminsMapping[_userAddress] = Admins(_userName, _userAddress, _userRole, true);
            emit UserRegistered(_userName, _userAddress, _userRole);
        }
        else{
            revert InvalidRole_UserRegistrationFailed();
        }
    }

    /**
     * @dev Verify a premium user.
     * Only the contract owner can verify premium users.
     * @param _premiumAddress The address of the premium user to verify.
     * @notice The premium user address must not be a zero address.
     * @notice The premium user address must not be registered as a normal user or admin.
     * @notice The premium user address must be registered as a premium user.
     * @notice The premium user address must not be already verified.
     * @notice Verifying a premium user sets their verification status to true.
     */
    function verifyPremiumUser(address _premiumAddress) public onlyOwner whenNotPaused{
        require(_premiumAddress != address(0), "Invalid Address");
        require(_premiumAddress != NormalUsersMApping[_premiumAddress].userAddress, "Only premium Addresses can be verifed");
        require(_premiumAddress != AdminsMapping[_premiumAddress].userAddress, "Only premium Addresses can be verifed");
        require(PremiumUsersMapping[_premiumAddress].isUserRegistered, "User with provided address is not Registered");
        require(!PremiumUsersMapping[_premiumAddress].isUserVerified, "Premium User with provided address is already verified");
        

        PremiumUsersMapping[_premiumAddress].isUserVerified = true;
        emit PremiumVerified( PremiumUsersMapping[_premiumAddress].userName, _premiumAddress);
    }


    /**
     * @dev Create a new phase.
     * Only the contract owner can create a new phase.
     * @param _reservedLimit The reserved limit for the new phase.
     * @param _premiumUserLimit The premium user limit for the new phase.
     * @param _normalUserLimit The normal user limit for the new phase.
     * @notice The reserved limit must not exceed the user minting limit.
     * @notice A new phase can only be created if the current phase is not active.
     * @notice The current phase must not have already been created.
     * @notice Creating a new phase updates the reserved limit, premium user limit, normal user limit, and sets the phase as created.
     */
    function createPhase(uint _reservedLimit, uint _premiumUserLimit, uint _normalUserLimit) public onlyOwner whenNotPaused{
        require(_reservedLimit <= usersMintLimit, "Reserved limit exceeds user minting limit");
        require(!phasesMapping[currentPhase].isActive, "Current Phase is activated, Can't create new phase");
        require(!phasesMapping[currentPhase].isCreated, "Phase is already created.");
        require(phasesMapping[currentPhase].reservedLimit == 0, "Phase is already created.");

        reservedLimitCurrentPhase = _reservedLimit;
        phasesMapping[currentPhase].reservedLimit = _reservedLimit;
        phasesMapping[currentPhase].premiumUserLimit = _premiumUserLimit;
        phasesMapping[currentPhase].normalUserLimit = _normalUserLimit;
        phasesMapping[currentPhase].isCreated = true;

        emit PhaseCreated("Phase Created Successfully", currentPhase, _reservedLimit);

    }


    /**
     * @dev Activate the current phase.
     * Only the contract owner can activate a phase.
     * @notice The current phase must have been created and not already active.
     * @notice Activating a phase sets its status to active.
     */
    function activatePhase() public onlyOwner whenNotPaused{
        require(phasesMapping[currentPhase].isCreated, "Phase is not created.");
        require(!phasesMapping[currentPhase].isActive, "Phase is already active");
        
        phasesMapping[currentPhase].isActive = true;

        emit PhaseActivated("Phase has been Acitvated Successfully", currentPhase, block.timestamp);
    }

    /**
     * @dev Deactivate the current phase.
     * Only the contract owner can deactivate a phase.
     * @notice The current phase must have been created and already active.
     * @notice Deactivating a phase sets its status to inactive and increments the current phase.
     */
    function deactivateCurrentPhase() public onlyOwner whenNotPaused{
        require(phasesMapping[currentPhase].isCreated, "Phase is not created.");
        require(phasesMapping[currentPhase].isActive, "Phase is already deactive");
        
        phasesMapping[currentPhase].isActive = false;

        emit PhaseDeActivated("Phase has been DeAcitvated Successfully", currentPhase, block.timestamp);
        currentPhase++;
    }


    /**
     * @dev Update the reserved limit for the current phase.
     * Only the contract owner can update the reserved limit.
     * @param _newReservedLimit The new reserved limit to be set.
     * @notice The current phase must have been created and active.
     * @notice The new limit must be greater than the already set limit.
     */
    function updateReservedLimit(uint256 _newReservedLimit) public onlyOwner whenNotPaused{
        require(phasesMapping[currentPhase].isCreated, "Phase is not created.");
        require(phasesMapping[currentPhase].isActive, "Phase is not Active");
        require(_newReservedLimit <= usersMintLimit + usersMintedBalance, "Reserved limit exceeds user minting limit");
        require(reservedLimitCurrentPhase - phasesMapping[currentPhase].reservedLimit < _newReservedLimit, "new limit should be greater than already minted limit in the phase");
        phasesMapping[currentPhase].reservedLimit = _newReservedLimit;

        emit ReserveLimitUpdated("New reserve limit set Successfully!", _newReservedLimit, block.timestamp);
    }




    /**
     * @dev Update the global limit for a user's minting capacity for all available addresses.
     * Only the contract owner can update the global limit.
     * @param _userAddress The address of the user whose limit will be updated.
     * @param _newLimit The new global limit to be set.
     * @notice The user's global limit will be updated if they are a premium or normal user.
     * @notice The new limit must be greater than the balance of the user's address.
     * @notice Multiple premium and normal users can have their limits updated.
     */
    function updateAllGlobalLimit(address[] memory _userAddress, uint256[] memory _newLimit) public onlyOwner whenNotPaused{
        require(_userAddress.length == _newLimit.length, "Input arrays length mismatch");

        for (uint256 i = 0; i < _userAddress.length; i++) {
            address user = _userAddress[i];
            uint256 newLimit = _newLimit[i];

            if (PremiumUsersMapping[user].isUserRegistered) {
                require(balanceOf(user) < newLimit, "Limit is less than the balance of the address");
                PremiumUsersMapping[user].userGlobalLimit = newLimit;

                emit GlobalLimitUpdated("Premium Global limit Updated Successfully!", user, newLimit, block.timestamp);
            }
            else if (NormalUsersMApping[user].isUserRegistered) {
                require(balanceOf(user) < newLimit, "Limit is less than the balance of the address");
                NormalUsersMApping[user].userGlobalLimit = newLimit;
                emit GlobalLimitUpdated("Normal Global limit Updated Successfully!", user, newLimit, block.timestamp);
            }
            else {
            revert Neither_Normal_nor_Premium_User();
            }
        }
    }


    /**
     * @dev Safely mint an NFT to the specified address with the given token ID and URI.
     *
     * @param tokenId The ID of the minted NFT.
     * @param uri The URI of the minted NFT.
     *
     * @notice Only registered users can mint NFTs.
     * @notice Minting is allowed only if the current phase is active.
     * @notice The user must have available minting limit.
     * @notice The phase's reserved limit must not be exceeded.
     * @notice If the user is a premium user, they must be verified and have not exceeded their global limit.
     */
    function safeMint(uint tokenId, string memory uri) public onlyActivePhase whenNotPaused{
        require(PremiumUsersMapping[msg.sender].isUserRegistered || NormalUsersMApping[msg.sender].isUserRegistered, "User is not registered");
        require(phasesMapping[currentPhase].isCreated, "Phase is not created.");
        require(tokenId < maxMintLimit, "Token ID should be less than the value of Max minting limit");
        require(usersMintLimit > 0, "User Minting Limit is not available");
        require(phasesMapping[currentPhase].reservedLimit > 0, "Phase reserved limit exceeded");

        if(PremiumUsersMapping[msg.sender].isUserRegistered){
            require(PremiumUsersMapping[msg.sender].isUserVerified != false, "User is not Verified, Can't Mint NFTs");
            require(balanceOf(msg.sender) < PremiumUsersMapping[msg.sender].userGlobalLimit, "Global Limit Exceeded, Can't Mint");
            require(phasesMapping[currentPhase].premiumUserLimit > phasesMapping[currentPhase].premiumUserBalance[msg.sender], "Limits Exceeds");
            phasesMapping[currentPhase].premiumUserBalance[msg.sender]++;


        }

        else{

            require(balanceOf(msg.sender) < NormalUsersMApping[msg.sender].userGlobalLimit, "Global Limit Exceeded, Can't Mint");
            require(phasesMapping[currentPhase].normalUserLimit > phasesMapping[currentPhase].normalUserBalance[msg.sender], "Normal User Limits Exceeds");
            phasesMapping[currentPhase].normalUserBalance[msg.sender]++;
        }
        usersMintLimit--;
        usersMintedBalance += 1;
        phasesMapping[currentPhase].reservedLimit--;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }


    /**
     * @dev Mint an NFT by an admin user.
     *
     * @param tokenId The ID of the minted NFT.
     * @param uri The URI of the minted NFT.
     *
     * @notice Only admin users can mint NFTs, and the platform minting limit is applicable to admin users.
     * @notice Minting is allowed only if the current phase is active.
     * @notice The platform minting limit must be greater than 0.
     */
    function mintByAdmin(uint tokenId, string memory uri) public whenNotPaused{

        require(AdminsMapping[msg.sender].isUserRegistered, "Admin is not Registered yet");
        require(tokenId < maxMintLimit, "Token ID should be less than the value of Max minting limit");
        require(platformMintLimit > 0, "Platform limit exceeds");

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        platformMintLimit--;

    }


    /**
     * @dev Mint NFTs in bulk by a registered user.
     * 
     * @param uris The URIs of the minted NFTs.
     * @param tokenIds The IDs of the minted NFTs.
     * @param toAddresses The addresses to which the minted NFTs will be transferred.
     * 
     * @notice Only registered users can mint NFTs.
     * @notice Minting is allowed only if the current phase is active.
     * @notice The length of input arrays (uris, tokenIds, toAddresses) must be the same.
     * @notice The user must have available minting limit.
     * @notice The phase's reserved limit must not be exceeded.
     */
    function UsersBulkMint(string[] memory uris, uint256[] memory tokenIds, address[] memory toAddresses) public onlyActivePhase whenNotPaused
    {
        require(uris.length == tokenIds.length && tokenIds.length == toAddresses.length, "Input arrays length mismatch");
        require(PremiumUsersMapping[msg.sender].isUserRegistered || NormalUsersMApping[msg.sender].isUserRegistered, "User is not registered");
        require(usersMintLimit - uris.length > 0, "User Minting Limit is not available");
        require(phasesMapping[currentPhase].reservedLimit - uris.length > 0, "Phase reserved limit exceeded");
    
    


        for (uint256 i = 0; i < uris.length; i++) {

            require(tokenIds[i] < maxMintLimit, "Token ID exceeds the maximum minting limit");


            if(PremiumUsersMapping[msg.sender].isUserRegistered){
                require(PremiumUsersMapping[msg.sender].isUserVerified, "User is not Verified, Can't Mint NFTs");
                require(balanceOf(msg.sender) + (uris.length - i) <= PremiumUsersMapping[msg.sender].userGlobalLimit, "Global Limit Exceeded, Can't Mint");
                require(phasesMapping[currentPhase].premiumUserLimit >= phasesMapping[currentPhase].premiumUserBalance[msg.sender] + (uris.length - i), "PremiumLimit per address Exceeds");
                phasesMapping[currentPhase].premiumUserBalance[msg.sender]++;

            }

            else{
                require(balanceOf(msg.sender) + (uris.length - i) <= NormalUsersMApping[msg.sender].userGlobalLimit, "Global Limit Exceeded, Can't Mint");
                require(phasesMapping[currentPhase].normalUserLimit >= phasesMapping[currentPhase].normalUserBalance[msg.sender] + (uris.length - i), "NormalLimit per address Exceeds");
                phasesMapping[currentPhase].normalUserBalance[msg.sender]++;
            }

        usersMintLimit--;
        usersMintedBalance += 1;
        phasesMapping[currentPhase].reservedLimit--;

        _safeMint(toAddresses[i], tokenIds[i]);
        _setTokenURI(tokenIds[i], uris[i]);
        }
    }

    /**
     * @dev Mint multiple NFTs in bulk by an admin user.
     *
     * @param uri The URIs of the minted NFTs.
     * @param tokenid The IDs of the minted NFTs.
     *
     * @notice The length of the uri and tokenid arrays must be the same.
     * @notice Only an admin user is allowed to mint.
     * @notice The platform minting limit must be greater than 0.
     */
    function AdminBulkMint(string[]  memory uri , uint[]  memory tokenid) public whenNotPaused
    {
        require(uri.length == tokenid.length , " Please Enter Valid LENGTH");    
        require(AdminsMapping[msg.sender].isUserRegistered, "Only Admin is allowed to mint"); 
        require(platformMintLimit > 0, " Platform Minting Limit Exced!" );
     
        for(uint i =0;  i<uri.length; i++ )
        {
            require(tokenid[i] < maxMintLimit, "Token ID exceeds the maximum minting limit");
            _safeMint(msg.sender, tokenid[i]);
            _setTokenURI(tokenid[i], uri[i]);
            platformMintLimit--;
        }
     } 


    /**
     * @dev Transfers an NFT from one address to another. (An internal function of ERC721 Contract)
     *
     * @param from The address from which the NFT is being transferred.
     * @param to The address to which the NFT is being transferred.
     * @param tokenId The ID of the transferred NFT.
     *
     * @notice NFT transfers must be allowed (transferability is activated).
     */
    function _transfer(address from, address to, uint tokenId) internal whenNotPaused override(ERC721){
        require(isTransferable, "Transfer Deactivated");

        super._transfer(from,to,tokenId);
    }


    /**
     * @dev Allows the transfer of NFTs.
     *
     * @notice NFT transfers will not be already allowed (transferability is deactivated).
     */
    function allowTransfer() public whenNotPaused{
        require(!isTransferable, "Already Activated");
        isTransferable = true;
    }


    /**
     * @dev Updates the token URIs for multiple NFTs.
     *
     * @param DataArray An array of BulkNFTData containing the NFT IDs and new URIs.
     *
     * @notice This function allows the owner of each NFT to update its token URI.
     * @notice The caller must be the owner of the NFT.
     */
    function UpdatesHashes(BulkNFTData[]   memory DataArray )  public whenNotPaused
    {
        for(uint i =0;    i< DataArray.length;    i++ ){
            if(ownerOf(DataArray[i].tokenId) == msg.sender){

                _setTokenURI(DataArray[i].tokenId, DataArray[i].tokenUri);

                emit BulkHashesUpdated(DataArray[i].tokenId, DataArray[i].tokenUri, true);

            }
        }  
    }



    /**
     * @dev Get the NFTs owned by a specific address.
     *
     * @param userAddress The address of the user.
     * @return An array of BulkNFTData containing the NFT IDs and URIs.
     *
     * @notice This function retrieves the NFTs owned by a specific address.
     * @notice The userAddress must have a non-zero NFT balance.
     */
    function getNFTsByAddress(address userAddress) public whenNotPaused returns (BulkNFTData[] memory) {
        require(balanceOf(userAddress) > 0, "userAddress has zero Balance");
        uint256 balance = balanceOf(userAddress);
        BulkNFTData[] memory nfts = new BulkNFTData[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(userAddress, i);
            string memory uri = tokenURI(tokenId);
            nfts[i] = BulkNFTData(tokenId, uri);

            emit NftFetchedByAddress("NFT Fetched Successfully!", userAddress, tokenId, uri);
        }

        return nfts;
    }


    






    // The following functions are overrides required by Solidity.

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}