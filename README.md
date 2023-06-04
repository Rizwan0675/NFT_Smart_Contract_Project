# NFT_Smart_Contract_Project
The project aims to develop a robust and secure Solidity smart contract that facilitates the minting and management of Non-Fungible Tokens (NFTs) with a wide range of features and restrictions. The contract will be seamlessly integrated with the OpenSea testnet platform, enabling effortless listing and trading of the minted NFTs.

## The key requirements of the contract are as follows:

## 1. Users and Limitations:
The contract will manage two types of users: Premium Users and Normal Users.
Different limits will be set for each user type: Max Minting Limit, Platform Minting Limit, and User Minting Limit.
The User Minting Limit is calculated as the difference between the Max Minting Limit and the Platform Minting Limit.

## 2. Phase-wise Minting Approach:
The contract follows a phase-wise minting approach.
The owner of the contract creates a phase and sets a reserved limit for that phase.
Premium and Normal users have separate limits per address for minting NFTs.
If the reserved limit for a phase is set to 50, both Premium and Normal users cannot mint more than 50 NFTs in total.
Minting is not allowed if the limit for each address is reached, and the reserved limit cannot exceed the user's minting limit.

## 3. Phase Activation and Deactivation:
The owner can create a phase and must activate it to allow minting by users.
Only one phase can be active at a time, and the owner needs to deactivate the current phase before creating a new one.
Each new phase can have a different reserved limit and per-address limits.
Once a phase is deactivated, it cannot be reactivated.

## 4. Platform and Global Limits:
Platform Minting Limit is applicable only to admin addresses.
A global limit is set, and when reached, no address can mint additional NFTs, even if the user has remaining limits in the current phase.
Premium users can only mint when allowed by the owner.

## 5. Contract Functionality and Updates:
The contract provides various functions to update the global User Minting Limit, phase reserved limits, and bulk metadata hashes for NFTs.
Transfer functionality can be deactivated by the owner, preventing NFT transfers.
Bulk minting functions are available for users and admin to mint multiple NFTs at once.
NFTs can be fetched by address.
All contract functions can be paused by the contract owner.

## 6. NFT Attributes and OpenSea Listing:
The NFT contract will store the following attributes for each NFT: ID and Metadata hash.
The NFTs will be listed on the OpenSea testnet platform.


# Conclusion
The contract aims to provide a secure and controlled environment for minting NFTs, ensuring that users, limits, and phases are managed effectively. Integration with the OpenSea testnet allows for the listing and trading of the NFT collection, enhancing its visibility and accessibility.
