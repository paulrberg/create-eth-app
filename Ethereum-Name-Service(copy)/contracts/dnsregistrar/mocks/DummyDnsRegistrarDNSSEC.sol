/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Ethereum-Name-Service?utm=code
  */
  
  pragma solidity ^0.8.4;

contract DummyDNSSEC {
    uint16 expectedType;
    bytes expectedName;
    uint32 inception;
    uint64 inserted;
    bytes20 hash;

    function setData(
        uint16 _expectedType,
        bytes memory _expectedName,
        uint32 _inception,
        uint64 _inserted,
        bytes memory _proof
    ) public {
        expectedType = _expectedType;
        expectedName = _expectedName;
        inception = _inception;
        inserted = _inserted;
        if (_proof.length != 0) {
            hash = bytes20(keccak256(_proof));
        }
    }

    function rrdata(
        uint16 dnstype,
        bytes memory name
    ) public view returns (uint32, uint64, bytes20) {
        require(dnstype == expectedType);
        require(keccak256(name) == keccak256(expectedName));
        return (inception, inserted, hash);
    }
}
