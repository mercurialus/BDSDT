// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ModExpLib.sol";

/**
 * @title ZKPSimulator
 * @dev Simulates the original ZKP scheme from the BDSDT paper for IoT device registration.
 *
 * In this scheme:
 *  - Each IoT device has a secret timestamp (TS).
 *  - The device computes its commitment: W = generator^(TS) mod modulus.
 *  - The device registers its commitment on-chain.
 *  - Later, the verifier sends a challenge (challengeExp and challengeMul).
 *  - The device computes:
 *         M = (W)^(challengeExp) mod modulus,
 *         and then computes responseProduct = (M * challengeMul) mod modulus.
 *  - The contract recovers M by computing:
 *         recoveredM = (responseProduct * modInverse(challengeMul)) mod modulus,
 *    where modInverse is computed via Fermat's little theorem using modExp.
 *  - It then verifies that recoveredM equals expected M.
 */
contract ZKPSimulator {
    using ModExpLib for uint256;

    // Global parameters: generator (L) and modulus (R).
    uint public generator;
    uint public modulus;

    // Mapping to store each device's commitment (W = generator^(TS) mod modulus).
    mapping(address => uint) public deviceCommitment;

    // Constructor sets the global parameters.
    constructor(uint _generator, uint _modulus) {
        generator = _generator;
        modulus = _modulus;
    }

    /**
     * @notice Register the device by storing its commitment.
     * @param commitmentValue The device's computed commitment: W = generator^(TS) mod modulus.
     */
    function registerDevice(uint commitmentValue) public {
        deviceCommitment[msg.sender] = commitmentValue;
    }

    /**
     * @notice Verify the device's response to a challenge.
     * @param challengeExp The challenge exponent provided by the verifier.
     * @param responseProduct The device's response: (M * challengeMul) mod modulus.
     * @param challengeMul The challenge multiplier provided by the verifier.
     * @return True if the response is valid; false otherwise.
     *
     * Verification steps:
     *  1. Retrieve the stored commitment W.
     *  2. Compute expectedM = W^(challengeExp) mod modulus.
     *  3. Compute the modular inverse of challengeMul: invChallengeMul = challengeMul^(modulus-2) mod modulus.
     *  4. Recover M: recoveredM = (responseProduct * invChallengeMul) mod modulus.
     *  5. Check if recoveredM equals expectedM.
     */
    function verifyResponse(
        uint challengeExp,
        uint responseProduct,
        uint challengeMul
    ) public view returns (bool) {
        uint W = deviceCommitment[msg.sender];
        require(W != 0, "Device not registered");

        // Compute expectedM = W^(challengeExp) mod modulus using the modExp precompile.
        uint expectedM = W.modExp(challengeExp, modulus);

        // Compute modular inverse of challengeMul using Fermat's little theorem:
        // invChallengeMul = challengeMul^(modulus-2) mod modulus.
        uint invChallengeMul = ModExpLib.modExp(
            challengeMul,
            modulus - 2,
            modulus
        );

        // Recover M: recoveredM = (responseProduct * invChallengeMul) mod modulus.
        uint recoveredM = mulmod(responseProduct, invChallengeMul, modulus);

        return (recoveredM == expectedM);
    }
}
