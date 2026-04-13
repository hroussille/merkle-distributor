import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ethers } from "ethers";

export type ClaimData = {
  index: BigInt;
  account: ethers.AddressLike;
  amount: BigInt;
};

async function main() {
  // 1) Formatted Test input
  const values: ClaimData[] = [];

  for (let i = 0; i < 10; i++) {
    values.push({
      index: BigInt(i),
      account: ethers.Wallet.createRandom().address,
      amount: BigInt((i + 1) * 100),
    });
  }

  // 2) Create the Merkle Tree
  const tree = StandardMerkleTree.of(
    values.map((v) => [v.index, v.account, v.amount]),
    ["uint256", "address", "uint256"],
  );

  // 3) Log the Merkle Root
  console.log("Merkle Root:", tree.root);

  // 4) Log the Proofs for each entry
  values.forEach((v) => {
    const proof = tree.getProof([v.index, v.account, v.amount]);
    console.log(`Proof for index ${v.index}:`, proof);
    console.log(`Full entry:`, v);
  });

  // 5) Create a solidity file with the tree data
  const fs = require("fs");
  const fileContent = `// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TestMerkleTree {
    bytes32 public constant MERKLE_ROOT = 0x${tree.root.slice(2)};
    
    struct Claim {
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] proof;
    }

    mapping(uint256 => Claim) public claims;

    constructor() {
${values
  .map(
    (v) => `        claims[${v.index}] = Claim({
            index: ${v.index},
            account: ${v.account},
            amount: ${v.amount},
            proof: new bytes32[](${
              tree.getProof([v.index, v.account, v.amount]).length
            })
        });

${tree
  .getProof([v.index, v.account, v.amount])
  .map(
    (p, i) =>
      `        claims[${v.index}].proof[${i}] = 0x${p.toString().slice(2)};`,
  )
  .join("\n")}
`,
  )
  .join("\n")}
    }
}
`;

  fs.writeFileSync("test/utils/TestMerkleTree.sol", fileContent);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
