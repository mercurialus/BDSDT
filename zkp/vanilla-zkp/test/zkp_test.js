const ZKPSimulator = artifacts.require("ZKPSimulator");

contract("ZKPSimulator", accounts => {
    // We'll simulate one device using accounts[1]
    const deviceAccount = accounts[1];

    // Global parameters (must match those in migration)
    const generator = 7;
    const modulus = 1000000007;

    // Helper function: JavaScript modular exponentiation.
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

    // Helper function: Compute modular inverse using Fermat's little theorem.
    function modInverse(a, modulus) {
        // Since modulus is prime, inverse is a^(modulus-2) mod modulus.
        return modExp(a, modulus - 2, modulus);
    }

    it("should register a device and successfully verify its challenge response", async () => {
        const zkpInstance = await ZKPSimulator.deployed();

        // --- DEVICE SIDE: Registration ---
        // Let the device's secret timestamp be TSi (this is the secret value).
        const secretTimestamp = 123456;
        // Compute the device's commitment: W = generator^(secretTimestamp) mod modulus.
        const deviceCommitment = modExp(generator, secretTimestamp, modulus);
        console.log("Device Commitment (W):", deviceCommitment);

        // The device registers itself by sending its commitment.
        await zkpInstance.registerDevice(deviceCommitment, { from: deviceAccount });

        // --- VERIFIER SIDE: Challenge ---
        // Verifier chooses a random challenge exponent and multiplier.
        const challengeExp = 333;  // The challenge exponent Q.
        const challengeMul = 99;   // The challenge multiplier X.

        // Device should compute: expectedM = (W)^(challengeExp) mod modulus.
        const expectedM = modExp(deviceCommitment, challengeExp, modulus);
        console.log("Expected M:", expectedM);

        // Device computes its response:
        // responseProduct = (expectedM * challengeMul) mod modulus.
        const responseProduct = (expectedM * challengeMul) % modulus;
        console.log("Response Product (K):", responseProduct);

        // --- DEVICE SIDE: Sending Response ---
        // The device sends its response to the verifier (via the smart contract).
        const verificationResult = await zkpInstance.verifyResponse(challengeExp, responseProduct, challengeMul, { from: deviceAccount });

        // Assert that the verification passes.
        assert(verificationResult, "ZKP response verification failed");
    });
});
