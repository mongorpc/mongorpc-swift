# !/bin/sh
set -e
git submodule foreach git pull origin main
protoc -I=proto --proto_path=proto --swift_out=Sources/MongoRPC \
    --grpc-swift_out=Client=true,Server=false:Sources/MongoRPC \
    proto/mongorpc/value.proto \
    proto/mongorpc/mongorpc.proto