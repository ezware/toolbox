#!/bin/bash
cid=$(docker ps | grep sonic-slave | cut -d' ' -f1)
docker exec -it $cid bash
