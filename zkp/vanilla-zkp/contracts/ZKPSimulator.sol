// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    ZKPSimulator simulates the original zero-knowledge proof (ZKP) scheme
    as described in the BDSDT paper for IoT device registration.

    In this scheme:
      - Each IoT device has a secret timestamp (TS), kept private.
      - The device computes its commitment:
          deviceCommitment = generator^(TS) mod modulus.
      - The device registers its deviceCommitment on-chain.
      - Later, the verifier issues a challenge consisting of:
          - A challenge exponent (challengeExp)
          - A challenge multiplier (challengeMul)
      - The device computes:
          M = (deviceCommitment)^(challengeExp) mod modulus,
          then responseProduct = (M * challengeMul) mod modulus.
      - The contract recovers M by multiplying responseProduct with the modular
        inverse of challengeMul modulo modulus.
      - The contract verifies that the recovered value matches the expected M.
      
    Note: All arithmetic is performed modulo a prime number 'modulus'.
*/

contract ZKPSimulator {
    // Global parameters: generator (L) and modulus (R)
    uint public generator;
    uint public modulus;

    // Mapping to store each device's commitment: W = generator^(TS) mod modulus.
    mapping(address => uint) public deviceCommitment;

    // Constructor sets the global parameters.
    constructor(uint _generator, uint _modulus) {
        generator = _generator;
        modulus = _modulus;
    }

    /**
     * @notice Register the device by storing its commitment.
     * @param commitmentValue The computed commitment: W = generator^(TS) mod modulus.
     */
    function registerDevice(uint commitmentValue) public {
        deviceCommitment[msg.sender] = commitmentValue;
    }

    /**
     * @notice Verify the device's challenge response.
     * @param challengeExp The challenge exponent (Q) provided by the verifier.
     * @param responseProduct The response computed by the device: (M * challengeMul) mod modulus.
     * @param challengeMul The challenge multiplier (X) provided by the verifier.
     * @return True if the response is valid; false otherwise.
     *
     * The verification steps are:
     * 1. Retrieve the stored commitment W for the device.
     * 2. Expected value: expectedM = (W)^(challengeExp) mod modulus.
     * 3. The device's response is K = (expectedM * challengeMul) mod modulus.
     * 4. Recover M by computing:
     *       recoveredM = (responseProduct * modInverse(challengeMul)) mod modulus.
     * 5. Check that recoveredM equals expectedM.
     */
    function verifyResponse(
        uint challengeExp,
        uint responseProduct,
        uint challengeMul
    ) public view returns (bool) {
        uint W = deviceCommitment[msg.sender];
        require(W != 0, "Device not registered");

        // Compute expectedM = W^(challengeExp) mod modulus.
        uint expectedM = powerMod(W, challengeExp, modulus);

        // Compute the modular inverse of challengeMul.
        uint invChallengeMul = modInverse(challengeMul, modulus);

        // Recover M by multiplying responseProduct with the inverse modulo modulus.
        uint recoveredM = (responseProduct * invChallengeMul) % modulus;

        // Return true if recoveredM equals expectedM.
        return (recoveredM == expectedM);
    }

    /**
     * @notice Compute modular exponentiation.
     * @dev Returns (base^exponent) % modulus.
     * @param base The base value.
     * @param exponent The exponent.
     * @param modulus The modulus.
     * @return result The result of (base^exponent) mod modulus.
     */
    function powerMod(
        uint base,
        uint exponent,
        uint modulus
    ) internal pure returns (uint result) {
        result = 1;
        base = base % modulus;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = (result * base) % modulus;
            }
            exponent = exponent / 2;
            base = (base * base) % modulus;
        }
    }

    /**
     * @notice Compute the modular multiplicative inverse using Fermat's little theorem.
     * @dev Since modulus is prime, the inverse of a is a^(modulus-2) mod modulus.
     * @param a The number to invert.
     * @param modulus The modulus.
     * @return inverse The modular inverse of a modulo modulus.
     */
    function modInverse(
        uint a,
        uint modulus
    ) internal pure returns (uint inverse) {
        // a^(modulus-2) mod modulus gives the inverse when modulus is prime.
        return powerMod(a, modulus - 2, modulus);
    }
}
