#!/usr/bin/python



if __name__ == "__main__":

    # dataWithErrors = response.json()
    dataWithErrors = {
        "errors": [
            {
                "locations": [
                    {
                        "line": 8,
                        "column": 14
                    }
                ],
                "message": "Unexpected `unexpected character '\\''`\nExpected `IntValue`, `FloatValue`, `StringValue`, `BlockString`, `true`, `false`, `null` or `Name`"
            }
        ]
    }

    # dataWithNoErrors = response.json()
    # dataWithNoErrors =  {
    #     "data": {
    #         "orderFilledEvents": [
    #             {
    #                 "id": "0x2faf9484ee3ecdd092bd8f302d50153ca209008768967913b9091f9c3fd149c7_0x866c8f5c4823820af2167209b6f14ea3b8b6e7b4d8dd4a7ce8cbc51879a9dc34",
    #                 "transactionHash": "0x2faf9484ee3ecdd092bd8f302d50153ca209008768967913b9091f9c3fd149c7",
    #                 "timestamp": "1733677058"
    #             },
    #             {
    #                 "id": "0x2de6ffbef0cbefb1de4edb6a8279b7fec96a18228fabb5cf2aec7c2220ee120b_0xd876a4f6464040cc498faa6e0c1b562b36e98db5c734e37b8b9c6ad574d5b00c",
    #                 "transactionHash": "0x2de6ffbef0cbefb1de4edb6a8279b7fec96a18228fabb5cf2aec7c2220ee120b",
    #                 "timestamp": "1736172376"
    #             },
    #             {
    #                 "id": "0x7ccfcba07963636b3426a707bfb5de91f2b7e082d50220924c2bc62da5bf6ad4_0x2c823a585f4529532b8c697ed51d2224f1d609990c465bd5ab2b9eb8774d0f1c",
    #                 "transactionHash": "0x7ccfcba07963636b3426a707bfb5de91f2b7e082d50220924c2bc62da5bf6ad4",
    #                 "timestamp": "1736172492"
    #             },
    #             {
    #                 "id": "0x6a89b4b060ef73fe528d6df8ca0836758fe225f51e96bdbdd3414f6e614ee4a5_0x46aea7f960910eb35125f9658cd19c04b9130df9c14ef90763fd480ba01f735f",
    #                 "transactionHash": "0x6a89b4b060ef73fe528d6df8ca0836758fe225f51e96bdbdd3414f6e614ee4a5",
    #                 "timestamp": "1736173138"
    #             },
    #             {
    #                 "id": "0x36ec646a15b1c68ee7c48abe8df927c8be75ed7c4de49c31820780007059ea57_0xcc50f46b498bbfd5b22130afd7b8cca8b4d80b4d0a2c0753315f2f64c0c9a2fe",
    #                 "transactionHash": "0x36ec646a15b1c68ee7c48abe8df927c8be75ed7c4de49c31820780007059ea57",
    #                 "timestamp": "1736282158"
    #             },
    #             {
    #                 "id": "0x89412aaa4fe6af051a631fbe0431052135066794b076dd351361fd69b7a110b2_0xa2c7574f819722b74cc9cc8076603fbc438ddac2ccd72392a53adee6594c5342",
    #                 "transactionHash": "0x89412aaa4fe6af051a631fbe0431052135066794b076dd351361fd69b7a110b2",
    #                 "timestamp": "1736387404"
    #             },
    #             {
    #                 "id": "0xa0e8f8d4aec2a7d3e5d6f7fd79718139467c920abbd4a1997c6b5735ba8eb451_0x25800ab46c99c1f35fb5e56db58f234228a95addbe0e7b08ca2dbd0cec07be16",
    #                 "transactionHash": "0xa0e8f8d4aec2a7d3e5d6f7fd79718139467c920abbd4a1997c6b5735ba8eb451",
    #                 "timestamp": "1736652281"
    #             },
    #             {
    #                 "id": "0xdc9701a190430735ceee1942113af13ed2b4267a54d912d168a49f1705885b39_0xb2dae6b39a7842c320247334bc666f35ca8aa705531dd2936391cb60410f4637",
    #                 "transactionHash": "0xdc9701a190430735ceee1942113af13ed2b4267a54d912d168a49f1705885b39",
    #                 "timestamp": "1736812589"
    #             },
    #             {
    #                 "id": "0x0c101695624d1eb428f4322e7ca4e879c4010fea5aba6feb7ffb6e2497a77758_0x4e781a384d2ccf3afc990580273d3c35b1bb7e4f0f46211567d15aecd6d2f3bf",
    #                 "transactionHash": "0x0c101695624d1eb428f4322e7ca4e879c4010fea5aba6feb7ffb6e2497a77758",
    #                 "timestamp": "1736847536"
    #             },
    #             {
    #                 "id": "0xeb4b571cf109faa3cf2244d94664c48db6aa61a7f0778d818edd53130101394d_0x4e781a384d2ccf3afc990580273d3c35b1bb7e4f0f46211567d15aecd6d2f3bf",
    #                 "transactionHash": "0xeb4b571cf109faa3cf2244d94664c48db6aa61a7f0778d818edd53130101394d",
    #                 "timestamp": "1736847546"
    #             },
    #             {
    #                 "id": "0x3b7e079f971420d6207198d5e9fc0ed6d98f191dfbf3ee1b6202351ba745fe56_0x4e781a384d2ccf3afc990580273d3c35b1bb7e4f0f46211567d15aecd6d2f3bf",
    #                 "transactionHash": "0x3b7e079f971420d6207198d5e9fc0ed6d98f191dfbf3ee1b6202351ba745fe56",
    #                 "timestamp": "1736847826"
    #             },
    #             {
    #                 "id": "0xee2494925b06c69a639216e03e37288ac59d3b34d7eb2419e88fbf467f37ec97_0x3ce86b6132419f6bed7321beaf832e7906da270652bfc0644084de3e7b3b6219",
    #                 "transactionHash": "0xee2494925b06c69a639216e03e37288ac59d3b34d7eb2419e88fbf467f37ec97",
    #                 "timestamp": "1736967038"
    #             },
    #             {
    #                 "id": "0x9a6b2f42e350dd0b953ce3b7b6945f8353f0773fb54ed225de0827ae791e3529_0x7c8809cb88ee4bd7d949d8091aee8c703584e968ff8c3424d4fa4ea489820ceb",
    #                 "transactionHash": "0x9a6b2f42e350dd0b953ce3b7b6945f8353f0773fb54ed225de0827ae791e3529",
    #                 "timestamp": "1736985000"
    #             },
    #             {
    #                 "id": "0x17021b87f2be2198f7b2c39ed10dd2be8658582a75ce3c7b68dd3f7d1d7574bb_0xa5aa955b7095bb52c260031c1a19f49a1e87bff57275f5569768fcc4b65555ba",
    #                 "transactionHash": "0x17021b87f2be2198f7b2c39ed10dd2be8658582a75ce3c7b68dd3f7d1d7574bb",
    #                 "timestamp": "1736985269"
    #             },
    #             {
    #                 "id": "0x629ec0f90f843b356383329d2b52b9075be60c14023cf734ea9458ae703a8e8f_0x49a5502ce40f72f2199f1c46e7e47b50c4c08932e52ac9161c5b9e7a25af8e1a",
    #                 "transactionHash": "0x629ec0f90f843b356383329d2b52b9075be60c14023cf734ea9458ae703a8e8f",
    #                 "timestamp": "1737032610"
    #             },
    #             {
    #                 "id": "0x69b1b36f12c49f2ed58017feb6f729c208fc887fff7cdb343c3ff7e2068c0976_0xd555a215970d2f94968ea6ddfda07a162b65bcb4ca3da0774ac6e5a221df1fd8",
    #                 "transactionHash": "0x69b1b36f12c49f2ed58017feb6f729c208fc887fff7cdb343c3ff7e2068c0976",
    #                 "timestamp": "1737032730"
    #             },
    #             {
    #                 "id": "0x5d38e1e7f8173515cd3c428c258d8560a987d24df90e6ea0f36f9ecf0e7e675e_0xe42882b8ef49ebe31ca3b1adb3679d50858cf3ddf294cce33ebf28989e15206c",
    #                 "transactionHash": "0x5d38e1e7f8173515cd3c428c258d8560a987d24df90e6ea0f36f9ecf0e7e675e",
    #                 "timestamp": "1737123637"
    #             },
    #             {
    #                 "id": "0xdcf7bf349c88d36cf2945543161d2e65461a6ed967a14281741d7e0cce580fcb_0x6606f96b0a51f8c3b6e6bda090568d83a7d3c201fe1b2299a141ae2cacde3b8a",
    #                 "transactionHash": "0xdcf7bf349c88d36cf2945543161d2e65461a6ed967a14281741d7e0cce580fcb",
    #                 "timestamp": "1737125013"
    #             },
    #             {
    #                 "id": "0x9ae9048d611bb8b27d6e49553fe53f787ddc5240545a43b0d37ec88c025e1b98_0x6606f96b0a51f8c3b6e6bda090568d83a7d3c201fe1b2299a141ae2cacde3b8a",
    #                 "transactionHash": "0x9ae9048d611bb8b27d6e49553fe53f787ddc5240545a43b0d37ec88c025e1b98",
    #                 "timestamp": "1737125159"
    #             },
    #             {
    #                 "id": "0x9588c5084ef76f84f9e410f2976ff212f9c341f18a926e507988af09d6b40f07_0xde4dab382806218acf5b5f00248eb4be18f46dfbb7faee33cfa9f728117f2e83",
    #                 "transactionHash": "0x9588c5084ef76f84f9e410f2976ff212f9c341f18a926e507988af09d6b40f07",
    #                 "timestamp": "1737125565"
    #             }
    #         ],
    #         "ordersMatchedEvents": [
    #             {
    #                 "id": "0x91ba65d27afadf83e2f7e4e6edeaaa9331612f53a58f5fb171177acfb601baca",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "5000000"
    #             },
    #             {
    #                 "id": "0xd646b9f7c791d1e83f7f0c5522bf834c90cc4f5e9f78c50287d35a9f6d0214ac",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "5000000"
    #             },
    #             {
    #                 "id": "0x5b1da31365889fc5f651c80861f629de7ba56ee085dbd5b8ab73471e34c9c3fb",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "5000000"
    #             },
    #             {
    #                 "id": "0xbd6b1f43dc142a3b7949ba651c148df89cd1245aff85f555312ca26521a0f47d",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "5000000"
    #             },
    #             {
    #                 "id": "0xc66b6a06928b5544ce94e05d1e499ee7ade0e7463c70a89aecd8f6cea57d967e",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "10000000"
    #             },
    #             {
    #                 "id": "0xc8b8d61ae2b6a6839b3f4b65b82d5662b45c0d4b6839f20b1d2834acf7a1f4dc",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "10000000"
    #             },
    #             {
    #                 "id": "0x37124777a764479fca48548f445194e12224f0b982b86bd57483af0f9676fa58",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "10000000"
    #             },
    #             {
    #                 "id": "0x1fa7775e11e3b491fa182aed54d4bc5adfee663a90e122e766a12dedf3f7377e",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "10000000"
    #             },
    #             {
    #                 "id": "0xbdea0841ed8314dbe94c0240dd573ab0f93c91fbde13058225c5c153cf9c77a8",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "5100000"
    #             },
    #             {
    #                 "id": "0xbc68c073ed121768cbdda083b140408171a4d9ec36494769ae859db31551dc54",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "15000000"
    #             },
    #             {
    #                 "id": "0x526fbc7d06ad8bef1411817a7580a0766de14cfa751a832ebe80c90a797a52e6",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "7650000"
    #             },
    #             {
    #                 "id": "0x8c66fa049fe6cc22453116fd2a27530b37f47b75c3b2fe149bb31481758a40f7",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "5000000"
    #             },
    #             {
    #                 "id": "0xbe12918c0b54c96a0212207d11c54dde03f489566f8ef4fc7233f6a98f2eeb9c",
    #                 "takerAssetID": "7499310772839000939827460818108209122328490677343888452292252718053799772723",
    #                 "takerAmountFilled": "5000000"
    #             },
    #             {
    #                 "id": "0xe8d601e3e4a8494f1664dec75a0ab2194a9adf794d1a2f504464223dace2b745",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "5100000"
    #             },
    #             {
    #                 "id": "0xb308ecde64d4f4f4d8c148da0c9391abd4fa349a531c88b2a40921c44fec45cf",
    #                 "takerAssetID": "7499310772839000939827460818108209122328490677343888452292252718053799772723",
    #                 "takerAmountFilled": "1000000"
    #             },
    #             {
    #                 "id": "0x894bf03e8e512e94d033910bff5370efdf317b19ae79061ee6b1479cd74e1776",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "750000"
    #             },
    #             {
    #                 "id": "0x8e57248f1245afdf82c714900f0dd3510115c898f5808c689def5deb2a1562d2",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "500000"
    #             },
    #             {
    #                 "id": "0x2de31f498941e347b63fa7bb88076969d7f26322273e9a9fb95d902fad3d8a32",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "750000"
    #             },
    #             {
    #                 "id": "0xdc19f11051349cf78526c8d2f9949950ff11ab7f490034d04a9883b9b92649a7",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "25000000"
    #             },
    #             {
    #                 "id": "0x6312bcf0a894adc0ee05a7494a960baed52e38e140d2a243cd9efe607b79c5e6",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "20000000"
    #             },
    #             {
    #                 "id": "0xae5acf4b09ca9319b124a238808596b5b215d3f219c9478851046cc123a22747",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "20000000"
    #             },
    #             {
    #                 "id": "0xfccea478177a0323ffec6b523e88d0edc589c90f1d4cbabaa1f5356064908c6f",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "50000000"
    #             },
    #             {
    #                 "id": "0x834e800fc7a535b2d913d195b7de28be48651a6a963f43683fcc9d11c05dd77e",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "100000000"
    #             },
    #             {
    #                 "id": "0xe06011c5eff8194ab3a9bdcbcdff5026e8b37a12540ea83624062d855d4f443c",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "30000000"
    #             },
    #             {
    #                 "id": "0xcd390611b31ee51863a809379d787f9da681570a2a88f88768bd8b378bcbe583",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "30000000"
    #             },
    #             {
    #                 "id": "0xd5c695168e207fcdefe8c8c7cb8dc7bdda218e310fc1881224d319f299f475a7",
    #                 "takerAssetID": "0",
    #                 "takerAmountFilled": "10200000"
    #             },
    #             {
    #                 "id": "0x5f49287ded258dcf168139b29e4f842c897c98beed14f4be10f35873e7fa0594",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "18181818"
    #             },
    #             {
    #                 "id": "0xfbb9e6e065d68ef010c4ee1efa4a7f737c46391efa0791d687ea14daaf5f0914",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "36363636"
    #             },
    #             {
    #                 "id": "0x5773f9f682784fca29a379aecc89e1c22a9721f9049f2ab0ed8420bd62fdfa02",
    #                 "takerAssetID": "65818619657568813474341868652308942079804919287380422192892211131408793125422",
    #                 "takerAmountFilled": "100000000"
    #             },
    #             {
    #                 "id": "0x14d9df77d185f4fe843c2aba1163a4cf98c3cb0681323fc447fdeed84bbab9bf",
    #                 "takerAssetID": "7499310772839000939827460818108209122328490677343888452292252718053799772723",
    #                 "takerAmountFilled": "17916665"
    #             }
    #         ]
    #     }
    # }


    testData = {
        "data": {
            "orderFilledEvents": [
                {"id": "akjdna", 
                 "transactionHash": "adandjasd",
                 "someNumber": 2313},

                {"id": "sdgknjn", 
                 "transactionHash": "dadlakmfklgfmhkj3njknwkjn",
                 "someNumber": 7201}
            ],
            "Some other key": 12371,
            "One last key": "ajdnkajd"
        }
    }


    # print(json.dumps(dataWithNoErrors, indent = 2))





