/**
 *  @authors: [@xyzseer]
 *  @reviewers: [@nvm1410, @madhurMongia, @unknownunknown1, @mani99brar]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./WrappedERC20Factory.sol";
import {IConditionalTokens, IERC20} from "./Interfaces.sol";

/// @dev The Router contract replicates the main Conditional Tokens functions, but allowing to work with ERC20 outcomes instead of the ERC1155
contract Router is ERC1155Holder {
    IConditionalTokens public immutable conditionalTokens; // Conditional Tokens contract
    WrappedERC20Factory public immutable wrappedERC20Factory; // WrappedERC20Factory contract

    /// @dev Constructor
    /// @param _conditionalTokens Conditional Tokens contract
    /// @param _wrappedERC20Factory WrappedERC20Factory contract
    constructor(
        IConditionalTokens _conditionalTokens,
        WrappedERC20Factory _wrappedERC20Factory
    ) {
        conditionalTokens = _conditionalTokens;
        wrappedERC20Factory = _wrappedERC20Factory;
    }

    /// @notice Transfers the collateral to the Router, splits the position and sends the ERC20 outcome tokens back to the user
    /// @dev The ERC20 associated to each outcome must be previously created on the wrappedERC20Factory
    /// @dev Collateral tokens are deposited only if we are not splitting a deep position (parentCollectionId is bytes32(0))
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition to split
    /// @param amount The amount of collateral to split.
    function splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint amount
    ) public {
        if (parentCollectionId == bytes32(0)) {
            // transfer the collateral tokens to the Router
            collateralToken.transferFrom(msg.sender, address(this), amount);
        }
        _splitPosition(
            collateralToken,
            parentCollectionId,
            conditionId,
            amount
        );
    }

    /// @notice Splits a position and sends the ERC20 outcome tokens to the user
    /// @dev The ERC20 associated to each outcome must be previously created on the wrappedERC20Factory
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition to split
    /// @param amount The amount of collateral to split
    function _splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint amount
    ) internal {
        uint256[] memory partition = getPartition(
            conditionalTokens.getOutcomeSlotCount(conditionId)
        );

        if (parentCollectionId != bytes32(0)) {
            // it's splitting from a parent position, so we need to unwrap these tokens first
            // because they will be burnt to mint the child outcome tokens
            Wrapped1155Factory wrapped1155Factory = wrappedERC20Factory
                .wrapped1155Factory();

            uint256 tokenId = conditionalTokens.getPositionId(
                address(collateralToken),
                parentCollectionId
            );

            // unwrap ERC20
            IERC20 wrapped1155 = wrappedERC20Factory.tokens(tokenId);

            wrapped1155.transferFrom(msg.sender, address(this), amount);
            wrapped1155Factory.unwrap(
                address(conditionalTokens),
                tokenId,
                amount,
                address(this),
                wrappedERC20Factory.data(tokenId)
            );
        } else {
            collateralToken.approve(address(conditionalTokens), amount);
        }

        conditionalTokens.splitPosition(
            address(collateralToken),
            parentCollectionId,
            conditionId,
            partition,
            amount
        );

        // wrap & transfer the minted outcome tokens
        for (uint j = 0; j < partition.length; j++) {
            uint256 tokenId = getTokenId(
                collateralToken,
                parentCollectionId,
                conditionId,
                partition[j]
            );

            // wrap to erc20
            conditionalTokens.safeTransferFrom(
                address(this),
                address(wrappedERC20Factory.wrapped1155Factory()),
                tokenId,
                amount,
                wrappedERC20Factory.data(tokenId)
            );

            IERC20 wrapped1155 = wrappedERC20Factory.tokens(tokenId);

            // transfer the ERC20 back to the user
            wrapped1155.transfer(msg.sender, amount);
        }
    }

    /// @notice Merges positions and sends the collateral tokens to the user
    /// @dev The ERC20 associated to each outcome must be previously created on the wrappedERC20Factory
    /// @dev Collateral tokens are withdrawn only if we are not merging a deep position (parentCollectionId is bytes32(0))
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition to merge
    /// @param amount The amount of outcome tokens to merge
    function mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint amount
    ) public {
        _mergePositions(
            collateralToken,
            parentCollectionId,
            conditionId,
            amount
        );

        if (parentCollectionId == bytes32(0)) {
            // send collateral tokens back to the user
            collateralToken.transfer(msg.sender, amount);
        }
    }

    /// @notice Merges positions and receives the collateral tokens.
    /// @dev Callers to this function must send the collateral to the user.
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition to merge
    /// @param amount The amount of outcome tokens to merge
    function _mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint amount
    ) internal {
        uint256[] memory partition = getPartition(
            conditionalTokens.getOutcomeSlotCount(conditionId)
        );

        // we need to unwrap the outcome tokens because they will be burnt during the merge
        Wrapped1155Factory wrapped1155Factory = wrappedERC20Factory
            .wrapped1155Factory();

        for (uint j = 0; j < partition.length; j++) {
            uint256 tokenId = getTokenId(
                collateralToken,
                parentCollectionId,
                conditionId,
                partition[j]
            );

            // unwrap ERC20
            IERC20 wrapped1155 = wrappedERC20Factory.tokens(tokenId);

            wrapped1155.transferFrom(msg.sender, address(this), amount);
            wrapped1155Factory.unwrap(
                address(conditionalTokens),
                tokenId,
                amount,
                address(this),
                wrappedERC20Factory.data(tokenId)
            );
        }

        conditionalTokens.mergePositions(
            address(collateralToken),
            parentCollectionId,
            conditionId,
            partition,
            amount
        );

        if (parentCollectionId != bytes32(0)) {
            // it's merging from a parent position, so we need to wrap these tokens
            // and send them back to the user
            uint256 tokenId = conditionalTokens.getPositionId(
                address(collateralToken),
                parentCollectionId
            );

            // wrap to erc20
            conditionalTokens.safeTransferFrom(
                address(this),
                address(wrappedERC20Factory.wrapped1155Factory()),
                tokenId,
                amount,
                wrappedERC20Factory.data(tokenId)
            );

            IERC20 wrapped1155 = wrappedERC20Factory.tokens(tokenId);

            // transfer the ERC20 back to the user
            wrapped1155.transfer(msg.sender, amount);
        }
    }

    /// @notice Redeems positions and sends the collateral tokens to the user.
    /// @dev The ERC20 associated to each outcome must be previously created on the wrappedERC20Factory.
    /// @dev Collateral tokens are withdrawn only if we are not redeeming a deep position (parentCollectionId is bytes32(0))
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition used to redeem
    /// @param indexSets The index sets of the outcomes to redeem
    function redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata indexSets
    ) public {
        uint256 initialBalance;

        if (parentCollectionId == bytes32(0)) {
            initialBalance = collateralToken.balanceOf(address(this));
        }

        _redeemPositions(
            collateralToken,
            parentCollectionId,
            conditionId,
            indexSets
        );

        if (parentCollectionId == bytes32(0)) {
            uint256 finalBalance = collateralToken.balanceOf(address(this));

            if (finalBalance > initialBalance) {
                collateralToken.transfer(
                    msg.sender,
                    finalBalance - initialBalance
                );
            }
        }
    }

    /// @notice Redeems positions and receives the collateral tokens.
    /// @dev Callers to this function must send the collateral to the user.
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition used to redeem
    /// @param indexSets The index sets of the outcomes to redeem
    function _redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata indexSets
    ) internal {
        uint256 tokenId = 0;

        Wrapped1155Factory wrapped1155Factory = wrappedERC20Factory
            .wrapped1155Factory();

        for (uint j = 0; j < indexSets.length; j++) {
            tokenId = getTokenId(
                collateralToken,
                parentCollectionId,
                conditionId,
                indexSets[j]
            );

            // unwrap ERC20
            IERC20 wrapped1155 = wrappedERC20Factory.tokens(tokenId);

            uint256 amount = wrapped1155.balanceOf(msg.sender);

            wrapped1155.transferFrom(msg.sender, address(this), amount);

            wrapped1155Factory.unwrap(
                address(conditionalTokens),
                tokenId,
                amount,
                address(this),
                wrappedERC20Factory.data(tokenId)
            );
        }

        uint256 initialBalance = 0;

        if (parentCollectionId != bytes32(0)) {
            tokenId = conditionalTokens.getPositionId(
                address(collateralToken),
                parentCollectionId
            );
            initialBalance = conditionalTokens.balanceOf(
                address(this),
                tokenId
            );
        }

        conditionalTokens.redeemPositions(
            address(collateralToken),
            parentCollectionId,
            conditionId,
            indexSets
        );

        if (parentCollectionId != bytes32(0)) {
            uint256 finalBalance = conditionalTokens.balanceOf(
                address(this),
                tokenId
            );

            if (finalBalance > initialBalance) {
                // wrap to erc20
                conditionalTokens.safeTransferFrom(
                    address(this),
                    address(wrappedERC20Factory.wrapped1155Factory()),
                    tokenId,
                    finalBalance - initialBalance,
                    wrappedERC20Factory.data(tokenId)
                );

                IERC20 wrapped1155 = wrappedERC20Factory.tokens(tokenId);

                // transfer the ERC20 back to the user
                wrapped1155.transfer(msg.sender, finalBalance - initialBalance);
            }
        }
    }

    /// @dev Returns a partition containing the full set of outcomes
    /// @param size Number of outcome slots
    /// @return The partition containing the full set of outcomes
    function getPartition(uint256 size) internal pure returns (uint256[] memory) {
        uint256[] memory partition = new uint256[](size);

        for (uint i = 0; i < size; i++) {
            partition[i] = 1 << i;
        }

        return partition;
    }

    /// @notice Constructs a tokenId from a collateral token and an outcome collection.
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition used to redeem
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection
    function getTokenId(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint indexSet
    ) public view returns (uint256) {
        bytes32 collectionId = conditionalTokens.getCollectionId(
            parentCollectionId,
            conditionId,
            indexSet
        );
        return
            conditionalTokens.getPositionId(
                address(collateralToken),
                collectionId
            );
    }

    /// @notice Returns the address of the ERC-20 associated to the ERC-1155 outcome token.
    /// @param collateralToken The address of the ERC20 used as collateral
    /// @param parentCollectionId The Conditional Tokens parent collection id
    /// @param conditionId The id of the condition used to redeem
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection
    function getTokenAddress(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint indexSet
    ) external view returns (IERC20) {
        return
            wrappedERC20Factory.tokens(
                getTokenId(
                    collateralToken,
                    parentCollectionId,
                    conditionId,
                    indexSet
                )
            );
    }

    /// @notice Helper function used to know the redeemable outcomes associated to a conditionId.
    /// @param conditionId The id of the condition
    /// @return An array of outcomes where a true value indicates that the outcome is redeemable
    function getWinningOutcomes(
        bytes32 conditionId
    ) external view returns (bool[] memory) {
        bool[] memory result = new bool[](
            conditionalTokens.getOutcomeSlotCount(conditionId)
        );

        for (uint256 i = 0; i < result.length; i++) {
            result[i] = conditionalTokens.payoutNumerators(conditionId, i) == 0
                ? false
                : true;
        }

        return result;
    }
}
