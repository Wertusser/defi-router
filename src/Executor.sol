pragma solidity ^0.8.13;

import "./interfaces/IExecutor.sol";
import "./utils/LibCommands.sol";
import "./utils/Constants.sol";

contract Executor is IExecutor {
  using LibCommands for bytes[];

  address public immutable router;
  address private _caller;
  address private _owner;

  event CallBegin(address indexed target, bytes4 indexed selector, bytes payload);
  event CallEnd(address indexed target, bytes4 indexed selector, bytes result);

  error ExecutionFailed(uint256 command_index, address target, string message);

  modifier checkCaller() {
    address expectedCaller = _caller;
    require(expectedCaller == msg.sender, "Invalid caller");
    if (expectedCaller != router) {
      _caller = router;
    }
    _;
  }

  constructor(address router_) {
    router = router_;
  }

  function initialize() external {
    require(_caller == address(0), "Executor is already Initialized");
    _caller = router;
  }

  function run(bytes32[] calldata commands, bytes[] memory stack) external payable checkCaller {
    _execute(commands, stack);
  }

  function _execute(bytes32[] calldata commands, bytes[] memory state) internal returns (bytes[] memory) {
    bytes32 command;
    address target;
    uint256 flags;
    bytes32 indices;

    bool success;
    bytes memory outdata;

    for (uint256 i; i < commands.length; i++) {
      command = commands[i];
      flags = uint256(uint8(bytes1(command << 32)));
      target = address(uint160(uint256(command)));

      if (flags & Constants.FLAG_EXTENDED_COMMAND != 0) {
        indices = commands[i++];
      } else {
        indices = bytes32(uint256(command << 40) | Constants.SHORT_COMMAND_FILL);
      }
      if (flags & Constants.FLAG_CT_MASK == Constants.FLAG_CT_DELEGATECALL) {
        // delegate call
        (success, outdata) = target.delegatecall(state.buildInputs(bytes4(command), indices));
      } else if (flags & Constants.FLAG_CT_MASK == Constants.FLAG_CT_CALL) {
        // call
        (success, outdata) = target.call(state.buildInputs(bytes4(command), indices));
      } else if (flags & Constants.FLAG_CT_MASK == Constants.FLAG_CT_STATICCALL) {
        // static call
        (success, outdata) = target.staticcall(state.buildInputs(bytes4(command), indices));
      } else if (flags & Constants.FLAG_CT_MASK == Constants.FLAG_CT_VALUECALL) {
        // call with value
        uint256 calleth;
        bytes memory v = state[uint8(bytes1(indices))];
        require(v.length == 32, "_execute: value call has no value indicated.");
        assembly {
          calleth := mload(add(v, 0x20))
        }
        (success, outdata) = target.call{ value: calleth }(
          state.buildInputs(bytes4(command), bytes32(uint256(indices << 8) | Constants.IDX_END_OF_ARGS))
        );
      } else {
        revert("Invalid calltype");
      }

      if (!success) {
        if (outdata.length > 0) {
          assembly {
            outdata := add(outdata, 68)
          }
        }
        revert ExecutionFailed({
          command_index: i,
          target: target,
          message: outdata.length > 0 ? string(outdata) : "Unknown"
        });
      }

      if (flags & Constants.FLAG_TUPLE_RETURN != 0) {
        state.writeTuple(bytes1(command << 88), outdata);
      } else {
        state = state.writeOutputs(bytes1(command << 88), outdata);
      }
    }
    return state;
  }
}
