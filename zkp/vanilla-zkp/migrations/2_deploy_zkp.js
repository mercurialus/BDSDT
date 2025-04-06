const ZKPSimulator = artifacts.require("ZKPSimulator");

module.exports = function (deployer) {
    // Define generator and modulus. For testing, use generator = 7 and a large prime modulus.
    const generator = 7;
    const modulus = 1000000007; // A large prime
    deployer.deploy(ZKPSimulator, generator, modulus);
};
