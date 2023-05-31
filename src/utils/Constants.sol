pragma solidity ^0.8.13;

library Constants {
  uint256 internal constant MAX_BALANCE = type(uint256).max;
  address internal constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  bytes4 internal constant POSTPROCESS_SIG = bytes4(0xc2722916);
  bytes4 internal constant SWEEP_SIG = bytes4(0x55051e71);

  bytes32 internal constant DEPRECATED = bytes10(0x64657072656361746564);
  bytes32 internal constant STATIC_MASK = 0x0100000000000000000000000000000000000000000000000000000000000000;
  bytes32 internal constant RETURN_SIZE_MASK = 0x00FF000000000000000000000000000000000000000000000000000000000000;
  bytes32 internal constant OFFSETS_MASK = 0x0000000000000000000000000000000000000000000000000000000000000001;
  bytes32 internal constant REFS_MASK = 0x00000000000000000000000000000000000000000000000000000000000000FF;

  uint256 internal constant RETURN_SIZE_OFFSET = 240;
  uint256 internal constant LOCATION_OFFSET = 176;
  uint256 internal constant REFS_COUNT_LIMIT = 22;
  uint256 internal constant OFFSETS_COUNT_LIMIT = 64;

  uint256 internal constant GAS_CALL_OFFSET = 5000;
  uint256 internal constant BIPS_BASE = 10000000;
}
