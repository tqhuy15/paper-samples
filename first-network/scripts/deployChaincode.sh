export CHANNEL_NAME=mychannel
#path=$1
#language=$2
name=$1
version=$2
set -x
# create package chaincode both org1, org2
peer lifecycle chaincode package ${name}.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode/javascript/ --lang node --label ${name}_${version}
. scripts/utils.sh
setGlobals 0 1
# install chaincode on peer0.org1
peer lifecycle chaincode install ${name}.tar.gz
# Environment variables for PEER0 in Org2
setGlobals 0 2
peer lifecycle chaincode install ${name}.tar.gz
# Query installed peer
queryInstalled() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
  export CC_PACKAGE_ID=$(sed -n "/${name}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer${PEER}.org${ORG} has failed"
  echo PackageID is ${CC_PACKAGE_ID}
  echo "===================== Query installed successful on peer${PEER}.org${ORG} on channel ===================== "
  echo
}
queryInstalled 0 1
queryInstalled 0 2
#env org1
setGlobals 0 1
#approve org1
set -x
peer lifecycle chaincode approveformyorg --channelID $CHANNEL_NAME --name $name --version 1.0 --init-required --package-id $CC_PACKAGE_ID --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
#approve org2
setGlobals 0 2
peer lifecycle chaincode approveformyorg --channelID $CHANNEL_NAME --name $name --version 1.0 --init-required --package-id $CC_PACKAGE_ID --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
#check commit chaincode both 2 org
peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $name --version 1.0 --init-required --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
#commit chaincode both 2 org
peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID $CHANNEL_NAME --name $name --version 1.0 --sequence 1 --init-required --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
#invoke the chaincode both 2 org
peer chaincode invoke -o orderer.example.com:7050 --isInit --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n $name --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["initLedger"]}' --waitForEvent

