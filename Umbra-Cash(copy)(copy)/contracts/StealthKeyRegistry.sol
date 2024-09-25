/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Umbra-Cash?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract StealthKeyRegistry {
  // =========================================== Events ============================================

  /// @dev Event emitted when a user updates their registered stealth keys
  event StealthKeyChanged(
    address indexed registrant,
    uint256 spendingPubKeyPrefix,
    uint256 spendingPubKey,
    uint256 viewingPubKeyPrefix,
    uint256 viewingPubKey
  );

  // ======================================= State variables =======================================

  /// @dev The payload typehash used for EIP-712 signatures in setStealthKeysOnBehalf
  bytes32 public constant STEALTHKEYS_TYPEHASH =
    keccak256(
      "StealthKeys(uint256 spendingPubKeyPrefix,uint256 spendingPubKey,uint256 viewingPubKeyPrefix,uint256 viewingPubKey)"
    );

  /// @dev The domain separator used for EIP-712 sigatures in setStealthKeysOnBehalf
  bytes32 public immutable DOMAIN_SEPARATOR;

  /**
   * @dev Mapping used to store two secp256k1 curve public keys used for
   * receiving stealth payments. The mapping records two keys: a viewing
   * key and a spending key, which can be set and read via the `setStealthKeys`
   * and `stealthKey` methods respectively.
   *
   * The mapping associates the user's address to another mapping, which itself maps
   * the public key prefix to the actual key . This scheme is used to avoid using an
   * extra storage slot for the public key prefix. For a given address, the mapping
   * may contain a spending key at position 0 or 1, and a viewing key at position
   * 2 or 3. See the setter/getter methods for details of how these map to prefixes.
   *
   * For more on secp256k1 public keys and prefixes generally, see:
   * https://github.com/ethereumbook/ethereumbook/blob/develop/04keys-addresses.asciidoc#generating-a-public-key
   */
  mapping(address => mapping(uint256 => uint256)) keys;

  /**
   * @dev We wait until deployment to codify the domain separator because we need the
   * chainId and the contract address
   */
  constructor() {
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("Umbra Stealth Key Registry")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );
  }

  // ======================================= Set Keys ===============================================

  /**
   * @notice Sets stealth keys for the caller
   * @param _spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
   * @param _spendingPubKey The public key for generating a stealth address
   * @param _viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
   * @param _viewingPubKey The public key to use for encryption
   */
  function setStealthKeys(
    uint256 _spendingPubKeyPrefix,
    uint256 _spendingPubKey,
    uint256 _viewingPubKeyPrefix,
    uint256 _viewingPubKey
  ) external {
    _setStealthKeys(msg.sender, _spendingPubKeyPrefix, _spendingPubKey, _viewingPubKeyPrefix, _viewingPubKey);
  }

  /**
   * @notice Sets stealth keys for the registrant using an EIP-712 signature to
   * authenticate the update on their behalf.
   * @param _registrant The address for which stealth keys are being registered,
   * i.e. the address expected to be recovered from the provided signature
   * @param _spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
   * @param _spendingPubKey The public key for generating a stealth address
   * @param _viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
   * @param _viewingPubKey The public key to use for encryption
   * @param _v ECDSA signature component: Parity of the `y` coordinate of point `R`
   * @param _r ECDSA signature component: x-coordinate of `R`
   * @param _s ECDSA signature component: `s` value of the signature
   */
  function setStealthKeysOnBehalf(
    address _registrant,
    uint256 _spendingPubKeyPrefix,
    uint256 _spendingPubKey,
    uint256 _viewingPubKeyPrefix,
    uint256 _viewingPubKey,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    // create EIP-712 Digest
    bytes32 _digest =
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(
            abi.encode(
              STEALTHKEYS_TYPEHASH,
              _spendingPubKeyPrefix,
              _spendingPubKey,
              _viewingPubKeyPrefix,
              _viewingPubKey
            )
          )
        )
      );

    // recover the signing address and ensure it matches the registrant
    address _recovered = ecrecover(_digest, _v, _r, _s);
    require(_recovered == _registrant, "StealthKeyRegistry: Invalid Signature");

    // now that we know the registrant has authorized it, update the stealth keys
    _setStealthKeys(_registrant, _spendingPubKeyPrefix, _spendingPubKey, _viewingPubKeyPrefix, _viewingPubKey);
  }

  /**
   * @dev Internal method for setting stealth key that must be called after safety
   * check on registrant; see calling method for parameter details
   */
  function _setStealthKeys(
    address _registrant,
    uint256 _spendingPubKeyPrefix,
    uint256 _spendingPubKey,
    uint256 _viewingPubKeyPrefix,
    uint256 _viewingPubKey
  ) internal {
    require(
      (_spendingPubKeyPrefix == 2 || _spendingPubKeyPrefix == 3) &&
        (_viewingPubKeyPrefix == 2 || _viewingPubKeyPrefix == 3),
      "StealthKeyRegistry: Invalid Prefix"
    );

    emit StealthKeyChanged(_registrant, _spendingPubKeyPrefix, _spendingPubKey, _viewingPubKeyPrefix, _viewingPubKey);

    // Shift the spending key prefix down by 2, making it the appropriate index of 0 or 1
    _spendingPubKeyPrefix -= 2;

    // Ensure the opposite prefix indices are empty
    delete keys[_registrant][1 - _spendingPubKeyPrefix];
    delete keys[_registrant][5 - _viewingPubKeyPrefix];

    // Set the appropriate indices to the new key values
    keys[_registrant][_spendingPubKeyPrefix] = _spendingPubKey;
    keys[_registrant][_viewingPubKeyPrefix] = _viewingPubKey;
  }

  // ======================================= Get Keys ===============================================

  /**
   * @notice Returns the stealth key associated with an address.
   * @param _registrant The address whose keys to lookup.
   * @return spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
   * @return spendingPubKey The public key for generating a stealth address
   * @return viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
   * @return viewingPubKey The public key to use for encryption
   */
  function stealthKeys(address _registrant)
    external
    view
    returns (
      uint256 spendingPubKeyPrefix,
      uint256 spendingPubKey,
      uint256 viewingPubKeyPrefix,
      uint256 viewingPubKey
    )
  {
    if (keys[_registrant][0] != 0) {
      spendingPubKeyPrefix = 2;
      spendingPubKey = keys[_registrant][0];
    } else {
      spendingPubKeyPrefix = 3;
      spendingPubKey = keys[_registrant][1];
    }

    if (keys[_registrant][2] != 0) {
      viewingPubKeyPrefix = 2;
      viewingPubKey = keys[_registrant][2];
    } else {
      viewingPubKeyPrefix = 3;
      viewingPubKey = keys[_registrant][3];
    }

    return (spendingPubKeyPrefix, spendingPubKey, viewingPubKeyPrefix, viewingPubKey);
  }
}
