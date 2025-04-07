const ZKPSimulator = artifacts.require("ZKPSimulator");

contract("ZKPSimulator", accounts => {
    const deviceAccount = accounts[1];
    const generator = 7;
    const modulus = 1000000007;

    // Helper: JavaScript modular exponentiation.
    function modExp(base, exponent, modulus) {
        let result = 1;
        base = base % modulus;
        while (exponent > 0) {
            if (exponent % 2 === 1) {
                result = (result * base) % modulus;
            }
            exponent = Math.floor(exponent / 2);
            base = (base * base) % modulus;
        }
        return result;
    }

    // Helper: Compute modular inverse using Fermat's little theorem.
    function modInverse(a, modulus) {
        return modExp(a, modulus - 2, modulus);
    }

    it("should register a device and verify its challenge response using modExp precompile", async () => {
        const zkpInstance = await ZKPSimulator.deployed();

        // DEVICE SIDE: Registration
        // Let the device's secret timestamp be TSi (the secret value).
        const secretTimestamp = 123456;
        // Compute the device's commitment: W = generator^(secretTimestamp) mod modulus.
        const deviceCommitment = modExp(generator, secretTimestamp, modulus);
        console.log("Device Commitment (W):", deviceCommitment);

        // Register the device by sending the computed commitment.
        await zkpInstance.registerDevice(deviceCommitment, { from: deviceAccount });

        // VERIFIER SIDE: Create a challenge.
        const challengeExp = 333;  // Challenge exponent (Q).
        const challengeMul = 99;   // Challenge multiplier (X).

        // The device should compute M = W^(challengeExp) mod modulus.
        const expectedM = modExp(deviceCommitment, challengeExp, modulus);
        console.log("Expected M:", expectedM);

        // Then compute responseProduct = (M * challengeMul) mod modulus.
        const responseProduct = (expectedM * challengeMul) % modulus;
        console.log("Response Product (K):", responseProduct);

        // Send the challenge response to the smart contract.
        const verificationResult = await zkpInstance.verifyResponse(challengeExp, responseProduct, challengeMul, { from: deviceAccount });
        assert(verificationResult, "ZKP response verification failed");
    });
});
