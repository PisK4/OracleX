/// @use-src 0:"contracts/verifier.sol"
object "Verifier_40" {
    code {
        /// @src 0:61:412  "contract Verifier {..."
        mstore(64, memoryguard(128))
        if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }

        constructor_Verifier_40()

        let _1 := allocate_unbounded()
        codecopy(_1, dataoffset("Verifier_40_deployed"), datasize("Verifier_40_deployed"))

        return(_1, datasize("Verifier_40_deployed"))

        function allocate_unbounded() -> memPtr {
            memPtr := mload(64)
        }

        function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() {
            revert(0, 0)
        }

        /// @src 0:61:412  "contract Verifier {..."
        function constructor_Verifier_40() {

            /// @src 0:61:412  "contract Verifier {..."

        }
        /// @src 0:61:412  "contract Verifier {..."

    }
    /// @use-src 0:"contracts/verifier.sol"
    object "Verifier_40_deployed" {
        code {
            /// @src 0:61:412  "contract Verifier {..."
            mstore(64, memoryguard(128))

            if iszero(lt(calldatasize(), 4))
            {
                let selector := shift_right_224_unsigned(calldataload(0))
                switch selector

                case 0x8e760afe
                {
                    // verify(bytes)

                    external_fun_verify_39()
                }

                default {}
            }

            revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74()

            function shift_right_224_unsigned(value) -> newValue {
                newValue :=

                shr(224, value)

            }

            function allocate_unbounded() -> memPtr {
                memPtr := mload(64)
            }

            function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() {
                revert(0, 0)
            }

            function revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() {
                revert(0, 0)
            }

            function revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db() {
                revert(0, 0)
            }

            function revert_error_1b9f4a0a5773e33b91aa01db23bf8c55fce1411167c872835e7fa00a4f17d46d() {
                revert(0, 0)
            }

            function revert_error_15abf5612cd996bc235ba1e55a4a30ac60e6bb601ff7ba4ad3f179b6be8d0490() {
                revert(0, 0)
            }

            function revert_error_81385d8c0b31fffe14be1da910c8bd3a80be4cfa248e04f42ec0faea3132a8ef() {
                revert(0, 0)
            }

            // bytes
            function abi_decode_t_bytes_calldata_ptr(offset, end) -> arrayPos, length {
                if iszero(slt(add(offset, 0x1f), end)) { revert_error_1b9f4a0a5773e33b91aa01db23bf8c55fce1411167c872835e7fa00a4f17d46d() }
                length := calldataload(offset)
                if gt(length, 0xffffffffffffffff) { revert_error_15abf5612cd996bc235ba1e55a4a30ac60e6bb601ff7ba4ad3f179b6be8d0490() }
                arrayPos := add(offset, 0x20)
                if gt(add(arrayPos, mul(length, 0x01)), end) { revert_error_81385d8c0b31fffe14be1da910c8bd3a80be4cfa248e04f42ec0faea3132a8ef() }
            }

            function abi_decode_tuple_t_bytes_calldata_ptr(headStart, dataEnd) -> value0, value1 {
                if slt(sub(dataEnd, headStart), 32) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

                {

                    let offset := calldataload(add(headStart, 0))
                    if gt(offset, 0xffffffffffffffff) { revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db() }

                    value0, value1 := abi_decode_t_bytes_calldata_ptr(add(headStart, offset), dataEnd)
                }

            }

            function abi_encode_tuple__to__fromStack(headStart ) -> tail {
                tail := add(headStart, 0)

            }

            function external_fun_verify_39() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0, param_1 :=  abi_decode_tuple_t_bytes_calldata_ptr(4, calldatasize())
                fun_verify_39(param_0, param_1)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple__to__fromStack(memPos  )
                return(memPos, sub(memEnd, memPos))

            }

            function revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74() {
                revert(0, 0)
            }

            function array_length_t_bytes_calldata_ptr(value, len) -> length {

                length := len

            }

            function cleanup_t_uint256(value) -> cleaned {
                cleaned := value
            }

            function cleanup_t_rational_0_by_1(value) -> cleaned {
                cleaned := value
            }

            function identity(value) -> ret {
                ret := value
            }

            function convert_t_rational_0_by_1_to_t_uint256(value) -> converted {
                converted := cleanup_t_uint256(identity(cleanup_t_rational_0_by_1(value)))
            }

            function require_helper(condition) {
                if iszero(condition) { revert(0, 0) }
            }

            function cleanup_t_rational_800000_by_1(value) -> cleaned {
                cleaned := value
            }

            function convert_t_rational_800000_by_1_to_t_uint256(value) -> converted {
                converted := cleanup_t_uint256(identity(cleanup_t_rational_800000_by_1(value)))
            }

            function panic_error_0x11() {
                mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
                mstore(4, 0x11)
                revert(0, 0x24)
            }

            function checked_sub_t_uint256(x, y) -> diff {
                x := cleanup_t_uint256(x)
                y := cleanup_t_uint256(y)
                diff := sub(x, y)

                if gt(diff, x) { panic_error_0x11() }

            }

            function revert_error_987264b3b1d58a9c7f8255e93e81c77d86d6299019c33110a076957a3e06e2ae() {
                revert(0, 0)
            }

            function round_up_to_mul_of_32(value) -> result {
                result := and(add(value, 31), not(31))
            }

            function panic_error_0x41() {
                mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
                mstore(4, 0x41)
                revert(0, 0x24)
            }

            function finalize_allocation(memPtr, size) {
                let newFreePtr := add(memPtr, round_up_to_mul_of_32(size))
                // protect against overflow
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr)) { panic_error_0x41() }
                mstore(64, newFreePtr)
            }

            function allocate_memory(size) -> memPtr {
                memPtr := allocate_unbounded()
                finalize_allocation(memPtr, size)
            }

            function array_allocation_size_t_bytes_memory_ptr(length) -> size {
                // Make sure we can allocate memory without overflow
                if gt(length, 0xffffffffffffffff) { panic_error_0x41() }

                size := round_up_to_mul_of_32(length)

                // add length slot
                size := add(size, 0x20)

            }

            function copy_calldata_to_memory_with_cleanup(src, dst, length) {

                calldatacopy(dst, src, length)
                mstore(add(dst, length), 0)

            }

            function abi_decode_available_length_t_bytes_memory_ptr(src, length, end) -> array {
                array := allocate_memory(array_allocation_size_t_bytes_memory_ptr(length))
                mstore(array, length)
                let dst := add(array, 0x20)
                if gt(add(src, length), end) { revert_error_987264b3b1d58a9c7f8255e93e81c77d86d6299019c33110a076957a3e06e2ae() }
                copy_calldata_to_memory_with_cleanup(src, dst, length)
            }

            function convert_array_t_bytes_calldata_ptr_to_t_bytes_memory_ptr(value, length) -> converted  {

                // Copy the array to a free position in memory
                converted :=

                abi_decode_available_length_t_bytes_memory_ptr(value, length, calldatasize())

            }

            function array_dataslot_t_bytes_memory_ptr(ptr) -> data {
                data := ptr

                data := add(ptr, 0x20)

            }

            function array_length_t_bytes_memory_ptr(value) -> length {

                length := mload(value)

            }

            function shift_left_0(value) -> newValue {
                newValue :=

                shl(0, value)

            }

            function update_byte_slice_32_shift_0(value, toInsert) -> result {
                let mask := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                toInsert := shift_left_0(toInsert)
                value := and(value, not(mask))
                result := or(value, and(toInsert, mask))
            }

            function cleanup_t_bytes32(value) -> cleaned {
                cleaned := value
            }

            function convert_t_bytes32_to_t_bytes32(value) -> converted {
                converted := cleanup_t_bytes32(value)
            }

            function shift_right_0_unsigned(value) -> newValue {
                newValue :=

                shr(0, value)

            }

            function prepare_store_t_bytes32(value) -> ret {
                ret := shift_right_0_unsigned(value)
            }

            function update_storage_value_offset_0t_bytes32_to_t_bytes32(slot, value_0) {
                let convertedValue_0 := convert_t_bytes32_to_t_bytes32(value_0)
                sstore(slot, update_byte_slice_32_shift_0(sload(slot), prepare_store_t_bytes32(convertedValue_0)))
            }

            /// @ast-id 39
            /// @src 0:115:409  "function verify(bytes calldata proof) external {..."
            function fun_verify_39(var_proof_5_offset, var_proof_5_length) {

                /// @src 0:181:186  "proof"
                let _1_offset := var_proof_5_offset
                let _1_length := var_proof_5_length
                let expr_9_offset := _1_offset
                let expr_9_length := _1_length
                /// @src 0:181:193  "proof.length"
                let expr_10 := array_length_t_bytes_calldata_ptr(expr_9_offset, expr_9_length)
                /// @src 0:196:197  "0"
                let expr_11 := 0x00
                /// @src 0:181:197  "proof.length > 0"
                let expr_12 := gt(cleanup_t_uint256(expr_10), convert_t_rational_0_by_1_to_t_uint256(expr_11))
                /// @src 0:173:198  "require(proof.length > 0)"
                require_helper(expr_12)
                /// @src 0:230:239  "gasleft()"
                let expr_18 := gas()
                /// @src 0:211:239  "uint256 _gasLeft = gasleft()"
                let var__gasLeft_16 := expr_18
                /// @src 0:252:366  "while (true) {..."
                for {
                    } 1 {
                }
                {
                    /// @src 0:259:263  "true"
                    let expr_20 := 0x01
                    if iszero(expr_20) { break }
                    /// @src 0:284:293  "gasleft()"
                    let expr_22 := gas()
                    /// @src 0:296:304  "_gasLeft"
                    let _2 := var__gasLeft_16
                    let expr_23 := _2
                    /// @src 0:307:313  "800000"
                    let expr_24 := 0x0c3500
                    /// @src 0:296:313  "_gasLeft - 800000"
                    let expr_25 := checked_sub_t_uint256(expr_23, convert_t_rational_800000_by_1_to_t_uint256(expr_24))

                    /// @src 0:284:313  "gasleft() < _gasLeft - 800000"
                    let expr_26 := lt(cleanup_t_uint256(expr_22), cleanup_t_uint256(expr_25))
                    /// @src 0:280:355  "if (gasleft() < _gasLeft - 800000) {..."
                    if expr_26 {
                        /// @src 0:334:339  "break"
                        break
                        /// @src 0:280:355  "if (gasleft() < _gasLeft - 800000) {..."
                    }
                }
                /// @src 0:395:400  "proof"
                let _3_offset := var_proof_5_offset
                let _3_length := var_proof_5_length
                let expr_34_offset := _3_offset
                let expr_34_length := _3_length
                /// @src 0:385:401  "keccak256(proof)"
                let _4_mpos := convert_array_t_bytes_calldata_ptr_to_t_bytes_memory_ptr(expr_34_offset, expr_34_length)
                let expr_35 := keccak256(array_dataslot_t_bytes_memory_ptr(_4_mpos), array_length_t_bytes_memory_ptr(_4_mpos))
                /// @src 0:376:401  "_value = keccak256(proof)"
                update_storage_value_offset_0t_bytes32_to_t_bytes32(0x00, expr_35)
                let expr_36 := expr_35

            }
            /// @src 0:61:412  "contract Verifier {..."

        }

        data ".metadata" hex"a26469706673582212204a147eda8876dc2f3fbab29b52dafcced630e83b912f87dbe5e599c88c9415ec64736f6c634300081a0033"
    }

}