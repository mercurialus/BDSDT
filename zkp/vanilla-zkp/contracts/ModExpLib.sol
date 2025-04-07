// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ModExpLib
 * @dev Library for performing modular exponentiation using Ethereum's modExp precompile (EIP-198).
 */
library ModExpLib {
    /**
     * @notice Calculates (base^exponent) % modulus using the precompile.
     * @param base The base number.
     * @param exponent The exponent.
     * @param modulus The modulus.
     * @return result The result of (base^exponent) % modulus.
     */
    function modExp(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal view returns (uint256 result) {
        // Each parameter is 32 bytes.
        uint256 bl = 32;
        uint256 el = 32;
        uint256 ml = 32;
        uint256 size = bl + el + ml; // total length for lengths

        // Allocate memory for input: lengths (96 bytes) + base + exponent + modulus (each 32 bytes).
        bytes memory input = new bytes(96 + bl + el + ml);
        assembly {
            // Store lengths at the beginning of the input buffer.
            mstore(add(input, 32), bl) // length of base
            mstore(add(input, 64), el) // length of exponent
            mstore(add(input, 96), ml) // length of modulus
            // Store base, exponent, modulus right after the lengths.
            mstore(add(input, 128), base)
            mstore(add(input, 160), exponent)
            mstore(add(input, 192), modulus)
        }
        // Call the modExp precompile at address 0x05.
        bool success;
        bytes memory output = new bytes(32);
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                5,
                add(input, 32),
                mload(input),
                add(output, 32),
                32
            )
        }
        require(success, "ModExpLib: modExp precompile call failed");
        assembly {
            result := mload(add(output, 32))
        }
    }
}
