# HoT Docker Environment

## Build

```bash
    docker build -t hot-image-name .
```

## Run

### Non-producer

```bash
    docker run \
        --name your-container-name \
        -d \
        -v/your/data/path:/hot/data \
        -p your_server_port:8011 \
        -p yout_peer-port:9011 \
        -e NODE_TYPE="server" \
        -e PEER_NODES="peer1-server-node-host:9011#peer2-server-node-host:9011" \
        houseoftoken/hot:latest
```

### Producer

```bash
    docker run \
        --name your-container-name \
        -d \
        -v/your/data/path:/hot/data \
        -p your_server_port:8011 \
        -p yout_peer-port:9011 \
        -e NODE_TYPE="producer" \
        -e PEER_NODES="peer1-server-node-host:9011#peer2-server-node-host:9011" \
        houseoftoken/hot:latest
```

