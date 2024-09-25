/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/Moonbirds-Core?utm=code
  */
  
  // SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "Moonbirds-Core/@openzeppelin/contracts/interfaces/IERC721.sol";
import "Moonbirds-Core/@openzeppelin/contracts/utils/Strings.sol";
import "Moonbirds-Core/@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
@notice Allows holders of ERC721 tokens to redeem rights to some claim; for
example, the right to mint a token of some other collection.
*/
library ERC721Redeemer {
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection.
     */
    struct Claims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.Claims` and utilise the
        provided functions.
         */
        mapping(uint256 => uint256) _total;
    }

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection, given that there is only a single claim allowed per
    tokenId.
     */
    struct SingleClaims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.SingleClaims` and
        utilise the provided functions.
         */
        BitMaps.BitMap _claimed;
    }

    /**
    @notice Emitted when a token's claim is redeemed.
     */
    event Redemption(
        IERC721 indexed token,
        address indexed redeemer,
        uint256 tokenId,
        uint256 n
    );

    /**
    @notice Checks that the redeemer is allowed to redeem the claims for the
    tokenIds by being either the owner or approved address for all tokenIds, and
    updates the Claims to reflect this.
    @dev For more efficient gas usage, recurring values in tokenIds SHOULD be
    adjacent to one another as this will batch expensive operations. The
    simplest way to achieve this is by sorting tokenIds.
    @param tokenIds The token IDs for which the claims are being redeemed. If
    maxAllowance > 1 then identical tokenIds can be passed more than once; see
    dev comments.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        Claims storage claims,
        uint256 maxAllowance,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (maxAllowance == 0 || tokenIds.length == 0) {
            return 0;
        }

        // See comment for `endSameId`.
        bool multi = maxAllowance > 1;

        for (
            uint256 i = 0;
            i < tokenIds.length; /* note increment at end */

        ) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            uint256 n = 1;
            if (multi) {
                // If allowed > 1 we can save on expensive operations like
                // checking ownership / remaining allowance by batching equal
                // tokenIds. The algorithm assumes that equal IDs are adjacent
                // in the array.
                uint256 endSameId;
                for (
                    endSameId = i + 1;
                    endSameId < tokenIds.length &&
                        tokenIds[endSameId] == tokenId;
                    endSameId++
                ) {} // solhint-disable-line no-empty-blocks
                n = endSameId - i;
            }

            claims._total[tokenId] += n;
            if (claims._total[tokenId] > maxAllowance) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }
            i += n;

            emit Redemption(token, redeemer, tokenId, n);
        }

        return tokenIds.length;
    }

    /**
    @notice Checks that the redeemer is allowed to redeem the single claim for
    each of the tokenIds by being either the owner or approved address for all
    tokenIds, and updates the SingleClaims to reflect this.
    @param tokenIds The token IDs for which the claims are being redeemed. Only
    a single claim can be made against a tokenId.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        SingleClaims storage claims,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (tokenIds.length == 0) {
            return 0;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            if (claims._claimed.get(tokenId)) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }

            claims._claimed.set(tokenId);
            emit Redemption(token, redeemer, tokenId, 1);
        }
        return tokenIds.length;
    }

    /**
    @dev Reverts if neither the owner nor approved for the tokenId.
     */
    function requireOwnerOrApproved(
        IERC721 token,
        uint256 tokenId,
        address redeemer
    ) private view {
        if (
            token.ownerOf(tokenId) != redeemer &&
            token.getApproved(tokenId) != redeemer
        ) {
            revertWithTokenId(
                "ERC721Redeemer: not approved nor owner of",
                tokenId
            );
        }
    }

    /**
    @notice Reverts with the concatenation of revertMsg and tokenId.toString().
    @dev Used to save gas by constructing the revert message only as required,
    instead of passing it to require().
     */
    function revertWithTokenId(string memory revertMsg, uint256 tokenId)
        private
        pure
    {
        revert(string(abi.encodePacked(revertMsg, " ", tokenId.toString())));
    }

    /**
    @notice Returns the number of claimed redemptions for the token.
     */
    function claimed(Claims storage claims, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return claims._total[tokenId];
    }

    /**
    @notice Returns whether the token has had a claim made against it.
     */
    function claimed(SingleClaims storage claims, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return claims._claimed.get(tokenId);
    }
}
