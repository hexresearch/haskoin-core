module Units (tests) where

import Test.HUnit
import Test.Framework
import Test.Framework.Providers.HUnit

import Control.Monad.Trans

import Data.Maybe
import Data.Binary
import Data.Binary.Get
import Data.Binary.Put
import qualified Data.ByteString as BS

import Haskoin.Wallet
import Haskoin.Wallet.TxBuilder
import Haskoin.Protocol
import Haskoin.Crypto
import Haskoin.Util

-- BIP 0032 Test Vectors
-- https://en.bitcoin.it/wiki/BIP_0032_TestVectors

m1 :: XPrvKey
m1 = fromJust $ makeXPrvKey $ BS.pack [0..15]

tests =
    [ testGroup "BIP32 derivation vector 1" 
        [ testCase "Chain m" v1c1
        , testCase "Chain m/0'" v1c2
        , testCase "Chain m/0'/1" v1c3
        ] 
    , testGroup "Build Transactions" 
        [ testCase "Build PKHash Tx 1" buildPKHashTx1
        , testCase "Build PKHash Tx 2" buildPKHashTx2
        , testCase "Build PKHash Tx 3" buildPKHashTx3
        , testCase "Build PKHash Tx 4" buildPKHashTx4
        ] 
    , testGroup "Verify transaction (bitcoind /test/data/tx_valid.json)" 
        [ testCase "Verify Tx 1" $ verifyTxVector $ verifyTxVectors !! 0
        , testCase "Verify Tx 2" $ verifyTxVector $ verifyTxVectors !! 1
        ] 
    ]

v1c1 = do
    assertBool "xPrvID" $
        xPrvID m1 == 0x3442193e1bb70916e914552172cd4e2dbc9df811
    assertBool "xPrvFP" $
        xPrvFP m1 == 0x3442193e
    assertBool "xPrvAddr" $
        (addrToBase58 $ xPubAddr $ deriveXPubKey m1) == 
        "15mKKb2eos1hWa6tisdPwwDC1a5J1y9nma"
    assertBool "prvKey" $
        bsToInteger (toStrictBS $ runPut $ putPrvKey $ xPrvKey m1) ==
        0xe8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35
    assertBool "xPrvWIF" $
        xPrvWIF m1 == 
        "L52XzL2cMkHxqxBXRyEpnPQZGUs3uKiL3R11XbAdHigRzDozKZeW"
    assertBool "pubKey" $
        bsToInteger (encode' $ xPubKey $ deriveXPubKey m1) ==
        0x0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2
    assertBool "chain code" $
        bsToInteger (encode' $ xPrvChain m1) ==
        0x873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508
    assertBool "Base58 PrvKey" $
        xPrvExport m1 ==
        "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"
    assertBool "Base58 PubKey" $
        (xPubExport $ deriveXPubKey m1) ==
        "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"

v1c2 = do
    -- m/0'
    let m' = fromJust $ primeSubKey m1 0
    assertBool "xPrvID" $
        xPrvID m' == 0x5c1bd648ed23aa5fd50ba52b2457c11e9e80a6a7
    assertBool "xPrvFP" $
        xPrvFP m' == 0x5c1bd648
    assertBool "xPrvAddr" $
        (addrToBase58 $ xPubAddr $ deriveXPubKey m') == 
        "19Q2WoS5hSS6T8GjhK8KZLMgmWaq4neXrh"
    assertBool "prvKey" $
        bsToInteger (toStrictBS $ runPut $ putPrvKey $ xPrvKey m') ==
        0xedb2e14f9ee77d26dd93b4ecede8d16ed408ce149b6cd80b0715a2d911a0afea
    assertBool "xPrvWIF" $
        xPrvWIF m' == 
        "L5BmPijJjrKbiUfG4zbiFKNqkvuJ8usooJmzuD7Z8dkRoTThYnAT"
    assertBool "pubKey" $
        bsToInteger (encode' $ xPubKey $ deriveXPubKey m') ==
        0x035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56
    assertBool "chain code" $
        bsToInteger (encode' $ xPrvChain m') ==
        0x47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141
    assertBool "Base58 PrvKey" $
        xPrvExport m' ==
        "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7"
    assertBool "Base58 PubKey" $
        (xPubExport $ deriveXPubKey m') ==
        "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw"

v1c3 = do
    -- m/0'/1
    let m' = fromJust $ prvSubKey (fromJust $ primeSubKey m1 0) 1
    assertBool "xPrvID" $
        xPrvID m' == 0xbef5a2f9a56a94aab12459f72ad9cf8cf19c7bbe
    assertBool "xPrvFP" $
        xPrvFP m' == 0xbef5a2f9
    assertBool "xPrvAddr" $
        (addrToBase58 $ xPubAddr $ deriveXPubKey m') == 
        "1JQheacLPdM5ySCkrZkV66G2ApAXe1mqLj"
    assertBool "prvKey" $
        bsToInteger (toStrictBS $ runPut $ putPrvKey $ xPrvKey m') ==
        0x3c6cb8d0f6a264c91ea8b5030fadaa8e538b020f0a387421a12de9319dc93368
    assertBool "xPrvWIF" $
        xPrvWIF m' == 
        "KyFAjQ5rgrKvhXvNMtFB5PCSKUYD1yyPEe3xr3T34TZSUHycXtMM"
    assertBool "pubKey" $
        bsToInteger (encode' $ xPubKey $ deriveXPubKey m') ==
        0x03501e454bf00751f24b1b489aa925215d66af2234e3891c3b21a52bedb3cd711c
    assertBool "chain code" $
        bsToInteger (encode' $ xPrvChain m') ==
        0x2a7857631386ba23dacac34180dd1983734e444fdbf774041578e9b6adb37c19
    assertBool "Base58 PrvKey" $
        xPrvExport m' ==
        "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs"
    assertBool "Base58 PubKey" $
        (xPubExport $ deriveXPubKey m') ==
        "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ"

flipEndian :: Hash256 -> Hash256
flipEndian = decode' . BS.reverse . encode'

-- These test vectors have been generated from bitcoind raw transaction api

buildPKHashTx1 =
    assertBool "Build TX 1" $ (bsToHex $ encode' tx) == bitcoindTx
    where tx = fromRight $ buildPKHashTx 
                      [OutPoint prevId 14] 
                      [(toAddr,90000000)]
          prevId = flipEndian 
            0xeb29eba154166f6541ebcc9cbdf5088756e026af051f123bcfb526df594549db
          toAddr = "14LsRquZfURNFrzpcLVGdaHTfAPjjwiSPb"
          bitcoindTx = stringToBS "0100000001db494559df26b5cf3b121f05af26e0568708f5bd9ccceb41656f1654a1eb29eb0e00000000ffffffff01804a5d05000000001976a91424aa604689cc582292b97668bedd91dd5bf9374c88ac00000000"

buildPKHashTx2 =
    assertBool "Build TX 2" $ (bsToHex $ encode' tx) == bitcoindTx
    where tx = fromRight $ buildPKHashTx 
                   [OutPoint prevId1 0, OutPoint prevId2 2147483647] 
                   [(toAddr1,1),(toAddr2,2100000000000000)]
          prevId1 = flipEndian 
            0xeb29eba154166f6541ebcc9cbdf5088756e026af051f123bcfb526df594549db
          prevId2 = flipEndian 
            0x01000000000000000000000000000000000000000000000000000000000000
          toAddr1 = "14LsRquZfURNFrzpcLVGdaHTfAPjjwiSPb"
          toAddr2 = "19VCgS642vzEA1sdByoSn6GsWBwraV8D4n"
          bitcoindTx = stringToBS "0100000002db494559df26b5cf3b121f05af26e0568708f5bd9ccceb41656f1654a1eb29eb0000000000ffffffff0000000000000000000000000000000000000000000000000000000000000100ffffff7f00ffffffff0201000000000000001976a91424aa604689cc582292b97668bedd91dd5bf9374c88ac0040075af07507001976a9145d16672f53981ff21c5f42b40d1954993cbca54f88ac00000000"

buildPKHashTx3 =
    assertBool "Build TX 3" $ (bsToHex $ encode' tx) == bitcoindTx
    where tx = fromRight $ buildPKHashTx 
                   [OutPoint prevId1 0, OutPoint prevId2 2147483647] 
                   []
          prevId1 = flipEndian 
            0xeb29eba154166f6541ebcc9cbdf5088756e026af051f123bcfb526df594549db
          prevId2 = flipEndian 
            0x01000000000000000000000000000000000000000000000000000000000000
          bitcoindTx = stringToBS "0100000002db494559df26b5cf3b121f05af26e0568708f5bd9ccceb41656f1654a1eb29eb0000000000ffffffff0000000000000000000000000000000000000000000000000000000000000100ffffff7f00ffffffff0000000000"

buildPKHashTx4 =
    assertBool "Build TX 4" $ (bsToHex $ encode' tx) == bitcoindTx
    where tx = fromRight $ buildPKHashTx 
                   [] 
                   [(toAddr1,1),(toAddr2,2100000000000000)]
          toAddr1 = "14LsRquZfURNFrzpcLVGdaHTfAPjjwiSPb"
          toAddr2 = "19VCgS642vzEA1sdByoSn6GsWBwraV8D4n"
          bitcoindTx = stringToBS "01000000000201000000000000001976a91424aa604689cc582292b97668bedd91dd5bf9374c88ac0040075af07507001976a9145d16672f53981ff21c5f42b40d1954993cbca54f88ac00000000"

{- Test vectors from bitcoind -}
-- github.com/bitcoin/bitcoin/blob/master/src/test/data/tx_valid.json


verifyTxVectors :: [(OutPoint,String,String)]
verifyTxVectors = 
    [
      ( OutPoint 
          (flipEndian 0x60a20bd93aa49ab4b28d514ec10b06e1829ce6818ec06cd3aabd013ebcdc4bb1) 
          0
      , "514104cc71eb30d653c0c3163990c47b976f3fb3f37cccdcbedb169a1dfef58bbfbfaff7d8a473e7e2e6d317b87bafe8bde97e3cf8f065dec022b51d11fcdd0d348ac4410461cbdcc5409fb4b4d42b51d33381354d80e550078cb532a34bfa2fcfdeb7d76519aecc62770f5b0e4ef8551946d8a540911abe3e7854a26f39f58b25c15342af52ae"
      , "0100000001b14bdcbc3e01bdaad36cc08e81e69c82e1060bc14e518db2b49aa43ad90ba26000000000490047304402203f16c6f40162ab686621ef3000b04e75418a0c0cb2d8aebeac894ae360ac1e780220ddc15ecdfc3507ac48e1681a33eb60996631bf6bf5bc0a0682c4db743ce7ca2b01ffffffff0140420f00000000001976a914660d4ef3a743e3e696ad990364e555c271ad504b88ac00000000"
      )
    , ( OutPoint
          (flipEndian 0x60a20bd93aa49ab4b28d514ec10b06e1829ce6818ec06cd3aabd013ebcdc4bb1)
          0
      , "514104cc71eb30d653c0c3163990c47b976f3fb3f37cccdcbedb169a1dfef58bbfbfaff7d8a473e7e2e6d317b87bafe8bde97e3cf8f065dec022b51d11fcdd0d348ac4410461cbdcc5409fb4b4d42b51d33381354d80e550078cb532a34bfa2fcfdeb7d76519aecc62770f5b0e4ef8551946d8a540911abe3e7854a26f39f58b25c15342af52ae"
      , "0100000001b14bdcbc3e01bdaad36cc08e81e69c82e1060bc14e518db2b49aa43ad90ba260000000004A0048304402203f16c6f40162ab686621ef3000b04e75418a0c0cb2d8aebeac894ae360ac1e780220ddc15ecdfc3507ac48e1681a33eb60996631bf6bf5bc0a0682c4db743ce7ca2bab01ffffffff0140420f00000000001976a914660d4ef3a743e3e696ad990364e555c271ad504b88ac00000000"
      )
    ]

verifyTxVector :: (OutPoint,String,String) -> Assertion
verifyTxVector (op,bsScript,bsTx) =
    assertBool "Verify transaction" $ verifyTx tx [(Script ops,op)]
    where tx  = decode' (fromJust $ hexToBS $ stringToBS bsTx)
          ops = runGet' getScriptOps (fromJust $ hexToBS $ stringToBS bsScript)



