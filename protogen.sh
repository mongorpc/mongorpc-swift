# !/bin/sh

git submodule foreach git pull origin main

set -e

if [ -f mongorpc.proto ]
then 
    rm mongorpc.proto
fi 

# protoc mongorpc.proto --swift_out=. --grpc-swift_out=Client=true,Server=false:.

protoc --proto_path=proto --swift_out=./Sources/MongoRPC \
    --grpc-swift_out=Client=true,Server=false:./Sources/MongoRPC \
    proto/mongorpc/*.proto