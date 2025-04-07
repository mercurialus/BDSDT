const ZKPSimulator = artifacts.require("ZKPSimulator");

module.exports = function (deployer) {
  const generator = 7;
  const modulus = 1000000007; // A large prime for modular arithmetic.
  deployer.deploy(ZKPSimulator, generator, modulus);
};
