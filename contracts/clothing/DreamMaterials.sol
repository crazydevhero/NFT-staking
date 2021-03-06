// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../ERC1155/ERC1155Burnable.sol";
import "../DreamAccessControls.sol";

/**
 * @title Dream Material NFT a.k.a. child NFTs
 * @dev Issues ERC-1155 tokens which can be held by the parent ERC-721 contract
 */
contract DreamMaterials is ERC1155Burnable {
    // @notice event emitted on contract creation
    event DreamMaterialsDeployed();

    // @notice a single child has been created
    event ChildCreated(uint256 indexed childId);

    // @notice a batch of children have been created
    event ChildrenCreated(uint256[] childIds);

    string public name;
    string public symbol;

    // @notice current token ID pointer
    uint256 public tokenIdPointer;

    // @notice enforcing access controls
    DreamAccessControls public accessControls;

    constructor(
        string memory _name,
        string memory _symbol,
        DreamAccessControls _accessControls
    ) public {
        name = _name;
        symbol = _symbol;
        accessControls = _accessControls;
        emit DreamMaterialsDeployed();
    }

    ///////////////////////////
    // Creating new children //
    ///////////////////////////

    /**
     @notice Creates a single child ERC1155 token
     @dev Only callable with smart contact role
     @return id the generated child Token ID
     */
    function createChild(string calldata _uri) external returns (uint256 id) {
        require(
            accessControls.hasSmartContractRole(_msgSender()),
            "DreamMaterials.createChild: Sender must be smart contract"
        );

        require(
            bytes(_uri).length > 0,
            "DreamMaterials.createChild: URI is a blank string"
        );

        tokenIdPointer = tokenIdPointer.add(1);

        id = tokenIdPointer;
        _setURI(id, _uri);

        emit ChildCreated(id);
    }

    /**
     @notice Creates a batch of child ERC1155 tokens
     @dev Only callable with smart contact role
     @return tokenIds the generated child Token IDs
     */
    function batchCreateChildren(string[] calldata _uris)
        external
        returns (uint256[] memory tokenIds)
    {
        require(
            accessControls.hasSmartContractRole(_msgSender()),
            "DreamMaterials.batchCreateChildren: Sender must be smart contract"
        );

        require(
            _uris.length > 0,
            "DreamMaterials.batchCreateChildren: No data supplied in array"
        );

        tokenIds = new uint256[](_uris.length);
        for (uint256 i = 0; i < _uris.length; i++) {
            string memory uri = _uris[i];
            require(
                bytes(uri).length > 0,
                "DreamMaterials.batchCreateChildren: URI is a blank string"
            );
            tokenIdPointer = tokenIdPointer.add(1);

            _setURI(tokenIdPointer, uri);
            tokenIds[i] = tokenIdPointer;
        }

        // Batched event for GAS savings
        emit ChildrenCreated(tokenIds);
    }

    //////////////////////////////////
    // Minting of existing children //
    //////////////////////////////////

    /**
      @notice Mints a single child ERC1155 tokens, increasing its supply by the _amount specified. msg.data along with the
      parent contract as the recipient can be used to map the created children to a given parent token
      @dev Only callable with smart contact role
     */
    function mintChild(
        uint256 _childTokenId,
        uint256 _amount,
        address _beneficiary,
        bytes calldata _data
    ) external {
        require(
            accessControls.hasSmartContractRole(_msgSender()),
            "DreamMaterials.mintChild: Sender must be smart contract"
        );

        require(
            bytes(tokenUris[_childTokenId]).length > 0,
            "DreamMaterials.mintChild: Strand does not exist"
        );
        require(_amount > 0, "DreamMaterials.mintChild: No amount specified");

        _mint(_beneficiary, _childTokenId, _amount, _data);
    }

    /**
      @notice Mints a batch of child ERC1155 tokens, increasing its supply by the _amounts specified. msg.data along with the
      parent contract as the recipient can be used to map the created children to a given parent token
      @dev Only callable with smart contact role
     */
    function batchMintChildren(
        uint256[] calldata _childTokenIds,
        uint256[] calldata _amounts,
        address _beneficiary,
        bytes calldata _data
    ) external {
        require(
            accessControls.hasSmartContractRole(_msgSender()),
            "DreamMaterials.batchMintChildren: Sender must be smart contract"
        );

        require(
            _childTokenIds.length == _amounts.length,
            "DreamMaterials.batchMintChildren: Array lengths are invalid"
        );
        require(
            _childTokenIds.length > 0,
            "DreamMaterials.batchMintChildren: No data supplied in arrays"
        );

        // Check the strands exist and no zero amounts
        for (uint256 i = 0; i < _childTokenIds.length; i++) {
            uint256 strandId = _childTokenIds[i];
            require(
                bytes(tokenUris[strandId]).length > 0,
                "DreamMaterials.batchMintChildren: Strand does not exist"
            );

            uint256 amount = _amounts[i];
            require(
                amount > 0,
                "DreamMaterials.batchMintChildren: Invalid amount"
            );
        }

        _mintBatch(_beneficiary, _childTokenIds, _amounts, _data);
    }

    function updateAccessControls(DreamAccessControls _accessControls)
        external
    {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "DreamMaterials.updateAccessControls: Sender must be admin"
        );

        require(
            address(_accessControls) != address(0),
            "DreamMaterials.updateAccessControls: New access controls cannot be ZERO address"
        );

        accessControls = _accessControls;
    }
}
