// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TestMerkleTree {
    bytes32 public constant MERKLE_ROOT = 0x4a9ac1ae07e31d618ba002e708a473e5ceb9f1d6bf02c1747a9cca58096beb8a;
    
    struct Claim {
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] proof;
    }

    mapping(uint256 => Claim) public claims;

    constructor() {
        claims[0] = Claim({
            index: 0,
            account: 0xa2e1c65576D35C59b4C1655673cA1f5914c4C144,
            amount: 100,
            proof: new bytes32[](4)
        });

        claims[0].proof[0] = 0x26b2d3d4ad60b482b8427a96bc0cb513353be906ed1a1039426fc6179f1ab09c;
        claims[0].proof[1] = 0x05319e82094cdbd3c5c6f680e53dd207976e009c8a3d9dad6899e963ee015c90;
        claims[0].proof[2] = 0x429567c208df6926528c892742cb8859222a9cbae5689b5a39c30eb35fb7ac74;
        claims[0].proof[3] = 0x2adcfb959578925232d801ba98908523d81ffd5eac4abf1725667e2a272a4fdd;

        claims[1] = Claim({
            index: 1,
            account: 0x97C2C6093A3fE71c3bc003342a1E4Ae914f40DC5,
            amount: 200,
            proof: new bytes32[](3)
        });

        claims[1].proof[0] = 0x5c0fef3495996f6cdfc6a01738fb31500a150aa1ec83ae1a1cc182a4e4f4c7ae;
        claims[1].proof[1] = 0xd11b5f2e27c268c6f0b6d182c4d1e5fa6fee7062656a944f7b75b909fac09732;
        claims[1].proof[2] = 0x5a829acd40153efa5eef4935750bd9b36be854b6732d65c0bd8428d50d73eae9;

        claims[2] = Claim({
            index: 2,
            account: 0xdC0dF796Fd59213FdD0b6666E2359989C66F98FC,
            amount: 300,
            proof: new bytes32[](3)
        });

        claims[2].proof[0] = 0xd7b05c663ed23af2f88df9cb9f370394a527256aebea27386573c8de93a44aa4;
        claims[2].proof[1] = 0x6f082e384c9f87bde09f9430c7c44315eeb70a5acaad75be48e5034b70b8719d;
        claims[2].proof[2] = 0x2adcfb959578925232d801ba98908523d81ffd5eac4abf1725667e2a272a4fdd;

        claims[3] = Claim({
            index: 3,
            account: 0x833649b9c1C17b6f4D18de7Cb955A015d6b20192,
            amount: 400,
            proof: new bytes32[](4)
        });

        claims[3].proof[0] = 0x23e6a72abdb7a384764c0fe72635c3a58b17a90acf5eb6b6fba4f2f5859196ad;
        claims[3].proof[1] = 0x05319e82094cdbd3c5c6f680e53dd207976e009c8a3d9dad6899e963ee015c90;
        claims[3].proof[2] = 0x429567c208df6926528c892742cb8859222a9cbae5689b5a39c30eb35fb7ac74;
        claims[3].proof[3] = 0x2adcfb959578925232d801ba98908523d81ffd5eac4abf1725667e2a272a4fdd;

        claims[4] = Claim({
            index: 4,
            account: 0x0C804721fc3f051E662415f37790106d26A2218C,
            amount: 500,
            proof: new bytes32[](4)
        });

        claims[4].proof[0] = 0x3a4692b4581a3a6efcd654f700c7c8af92a3ae813e258645ae1afd29ebcce27c;
        claims[4].proof[1] = 0xfebdf59a43e1674fdc836b600fee30582f6c5329770483ea31dfdbfada3a2ec8;
        claims[4].proof[2] = 0x429567c208df6926528c892742cb8859222a9cbae5689b5a39c30eb35fb7ac74;
        claims[4].proof[3] = 0x2adcfb959578925232d801ba98908523d81ffd5eac4abf1725667e2a272a4fdd;

        claims[5] = Claim({
            index: 5,
            account: 0x902fdA54Dcf9EaE08eDe14A8235D4862d72E9832,
            amount: 600,
            proof: new bytes32[](3)
        });

        claims[5].proof[0] = 0x9583d604f0f12567c0f90ebb15eb03cd34dbbc57853dc5e3abc6fbec07669684;
        claims[5].proof[1] = 0x1fae8b82946b6ed1b70c9af556ce2318bc028ad73d811ff84f1acc98880523eb;
        claims[5].proof[2] = 0x5a829acd40153efa5eef4935750bd9b36be854b6732d65c0bd8428d50d73eae9;

        claims[6] = Claim({
            index: 6,
            account: 0x4fc53a59278C851933251f2664a5680361655e4e,
            amount: 700,
            proof: new bytes32[](3)
        });

        claims[6].proof[0] = 0x48a85544717b429348a618042b689a765afc16c65707916285762bfc3725e480;
        claims[6].proof[1] = 0xd11b5f2e27c268c6f0b6d182c4d1e5fa6fee7062656a944f7b75b909fac09732;
        claims[6].proof[2] = 0x5a829acd40153efa5eef4935750bd9b36be854b6732d65c0bd8428d50d73eae9;

        claims[7] = Claim({
            index: 7,
            account: 0xAC2C91443d7798E5532619C6281483544772FC14,
            amount: 800,
            proof: new bytes32[](3)
        });

        claims[7].proof[0] = 0xe361619eb11d4ebc078ad25c351cc7d69123c5fc4196d7016ed24faa4f48db66;
        claims[7].proof[1] = 0x6f082e384c9f87bde09f9430c7c44315eeb70a5acaad75be48e5034b70b8719d;
        claims[7].proof[2] = 0x2adcfb959578925232d801ba98908523d81ffd5eac4abf1725667e2a272a4fdd;

        claims[8] = Claim({
            index: 8,
            account: 0x2EB224f814Dd0d1b1600D7a4340D1ea232607cB7,
            amount: 900,
            proof: new bytes32[](3)
        });

        claims[8].proof[0] = 0x980384b04daa8feb60046abe7497ab63eeeafa8f1e076bf7cdb9976da0deeeb8;
        claims[8].proof[1] = 0x1fae8b82946b6ed1b70c9af556ce2318bc028ad73d811ff84f1acc98880523eb;
        claims[8].proof[2] = 0x5a829acd40153efa5eef4935750bd9b36be854b6732d65c0bd8428d50d73eae9;

        claims[9] = Claim({
            index: 9,
            account: 0xC6F6f85B33f3D48D1b92a97614408Bff04b0C983,
            amount: 1000,
            proof: new bytes32[](4)
        });

        claims[9].proof[0] = 0x36c075ea35fee5b853838b1976e208f3587c0a89381b6b60e5ca3d6ab4441672;
        claims[9].proof[1] = 0xfebdf59a43e1674fdc836b600fee30582f6c5329770483ea31dfdbfada3a2ec8;
        claims[9].proof[2] = 0x429567c208df6926528c892742cb8859222a9cbae5689b5a39c30eb35fb7ac74;
        claims[9].proof[3] = 0x2adcfb959578925232d801ba98908523d81ffd5eac4abf1725667e2a272a4fdd;

    }
}
