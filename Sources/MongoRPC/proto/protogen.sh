#!/bin/sh
set -e

if [ -f mongorpc.proto ]
then 
    rm mongorpc.proto
fi 

wget https://raw.githubusercontent.com/mongorpc/mongorpc/main/proto/mongorpc.proto

protoc mongorpc.proto --swift_out=. --grpc-swift_out=Client=true,Server=false:.