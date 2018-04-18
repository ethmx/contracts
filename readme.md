# Ethm Contracts

Ethereum package registry interface implementation. Publish packages separated
on major, minor and build version.

Basic example written in solidity:

```sol
Registry reg = Registry(REGISTRY_ADDR);

// Receive package hash
bytes32 hash = reg.register('hello_world'); // -> '0x5b07e077a81ffc6b47435f65a8727bcc542bc6fc0f25a56210efb1a74b88a5ae'

// Package BZZ address.
bytes32 bzz = bytes32(0xccef599d1a13bed9989e424011aed2c023fce25917864cd7de38a761567410b8);

reg.publish(hash, 0, 1, 0, bzz);
```

Now package `hello_world` has the latest version '0.1.0'. You can receive it's
bzz manifest address with `repo.getLatestMajor(repo.resolve('hello_world'))`.

See [example](./example/index.js) of web3.js usage.
