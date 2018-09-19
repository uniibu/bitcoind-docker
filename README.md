# bitcoind-docker
Bitcoin Core docker compose

## Requirements
- Docker CE (recommended v18.06.1-ce) [Install Docker](https://docs.docker.com/install/)
- The steps below assumes you also followed the steps on running docker on a non-root user [Run docker as non-root](https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user) If not, you must add the command `sudo` when running `docker-compose`
- `docker-compose` (recommended v1.22.0) [Install docker-compose](https://docs.docker.com/compose/install/)

## Installation
- Clone this repo `git clone https://github.com/uniibu/bitcoind-docker.git`
- Open the repository `cd bitcoind-docker`
- Open the `bitcoin.conf.env` file and edit with your preffered options. `nano bitcoin.conf.env`
  - It is important to change the `BITCOIND_RPCUSER` and `BITCOIND_RPCPW`
  - `BITCOIND_ARGUMENTS` are additional arguments that you want to pass to bitcoind
  - [List if available bitcoind command-line arguments](https://en.bitcoin.it/wiki/Running_Bitcoin#Command-line_arguments)
  - The default `BITCOIND_ARGUMENTS` assumes that you have atleast 16GB of ram. If you have less, please change the `-dbcache` value. Ex. If you have 8GB ram change it to `-dbcache=4000`

#### Note
The steps bellow assumes that you are in the `bitcoind-docker` directory

## Build and Start
- To build and start run `docker-compose up`
- This will automatically build the container and start it. Note using `docker-compose up` will create a new container, if you already have a container, just use `docker-compose start`
- If you just want to build without starting, use `docker-compose build`

## Start, Restart, Stop and Delete
- To start a container `docker-compose start`
- To restart a container `docker-compose restart`
- To stop a container `docker-compose stop`
- To delete a container including its networks, images, and volumes `docker-compose down`

## Changing configuration
If you decide to change the configuration `bitcoin.conf.env`, you must rebuild the container

- Stop the container `docker-compose stop`
- Edit the configuration `nano bitcoin.conf.env`
- Rebuild the container `docker-compose build`
- Start the container `docker-compose start`


