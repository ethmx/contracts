const Web3 = require('web3');

const {publishToSwarm} = require('./utils.js');
const {abi} = require('./contract.js');

const web3 = new Web3(new Web3('https://rinkeby.infura.io/'));

// Initialize new contract
const reg = new web3.eth.Contract(abi, '0x57147069B117fD911Da6c43F3fBdC54a7A7D8C1d');

// Register new package and publish initial version
async function register() {
  // Publish current directory
  const bzz = await publishToSwarm('.');

  // Register package and get it's name
  const hash = await reg.methods.register('registry_example').send();

  // Publish first version
  await reg.methods.publish(hash, 0, 1, 0, bzz).send();
}

// Publish new package version
async function publish(major, minor, build) {
  // Convert name to hash according to registry algorithm
  const hash = await reg.methods.resolve('registry_example').call();

  // Publish new version
  await reg.methods.publish(hash, major, minor, build, bzz).send();
}

exports.register = register;
exports.publish = publish;
