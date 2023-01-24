#!/bin/bash

echo -e "\033[0;35m"          
echo "██████╗  ██████╗ ██████╗  ██████╗██╗   ██╗ █████╗ ██╗"  
echo "██╔══██╗██╔═══██╗██╔══██╗██╔════╝██║   ██║██╔══██╗██║"    
echo "██████╔╝██║   ██║██████╔╝██║     ██║   ██║███████║██║  "   
echo "██╔══██╗██║   ██║██╔══██╗██║     ██║   ██║██╔══██║██║ "    
echo "██║  ██║╚██████╔╝██║  ██║╚██████╗╚██████╔╝██║  ██║███████╗"
echo "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝"
echo -e "\e[0m"

echo -e "\e[1m\e[32mWelcome to the Kujira Node Setup Script by Rorcual. This Script is based on the work done by KjNodes (https://github.com/kj89/) and uses the RPC from Mintthemoon for the state sync.\e[0m"

sleep 2         
                                                                                                                                                   
# set variables

read -p "What port prefix would you like to use (hit enter to default: 26) : " port
KUJIRA_PORT=${port:-26}

read -p "What is your wallet name (hit enter to default: wallet) : " wallet
WALLET=${wallet:-wallet}

read -p "What is your chain name (hit enter to default: kaiyo-1) : " chain
KUJIRA_CHAIN_ID=${chain:-kaiyo-1}

read -p "What is your node name (moniker) : " moniker
KUJIRA_NODE=$moniker


if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export KUJIRA_CHAIN_ID=kaiyo-1" >> $HOME/.bash_profile
echo "export KUJIRA_PORT=${KUJIRA_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "Your wallet name: \e[1m\e[32m$WALLET\e[0m"
echo -e "Your chain name: \e[1m\e[32m$KUJIRA_CHAIN_ID\e[0m"
echo -e "Your port: \e[1m\e[32m$KUJIRA_PORT\e[0m"
echo -e "Your node name: \e[1m\e[32m$KUJIRA_NODE\e[0m"
echo '================================================='

sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

# install go
ver="1.18.5"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
export PATH=$PATH:/usr/local/go/bin
source

go version

# Install Kujira Core 

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
cd $HOME
git clone https://github.com/Team-Kujira/core $HOME/kujira-core
cd $HOME/kujira-core
LATEST_TAG=$(git describe --tags)


sleep 1
echo -e "\e[1m\e[32m4. These are all the versions avaliable: \e[0m" && sleep 1
git tag
sleep 2
read -p "What version would you like to install (hit enter to install the latest version: $LATEST_TAG) :" version
KUJIRA_VERSION=${version:-$LATEST_TAG}
git checkout $KUJIRA_VERSION
make install
source $HOME/.bash_profile

kujirad config chain-id $KUJIRA_CHAIN_ID
kujirad config keyring-backend file
kujirad config node tcp://localhost:${KUJIRA_PORT}657

kujirad init $moniker --chain-id $KUJIRA_CHAIN_ID

echo -e "\e[1m\e[32m1. Checking Kujirad Version... \e[0m" && sleep 1
kujirad version

# download genesis and addrbook
wget -qO $HOME/.kujira/config/genesis.json "https://raw.githubusercontent.com/Team-Kujira/networks/master/mainnet/kaiyo-1.json"

# set peers and seeds
SEEDS="5a70fdcf1f51bb38920f655597ce5fc90b8b88b8@136.244.29.116:41656"
PEERS="9813378d0dceb86e57018bfdfbade9d863f6f3c8@3.38.73.119:26656,ccffabe81f2de8a81e171f93fe1209392bf9993f@65.108.234.59:26656,7878121e8fa201c836c8c0a95b6a9c7ac6e5b101@141.95.151.171:26656,0743497e30049ac8d59fee5b2ab3a49c3824b95c@198.244.200.196:26656,2efead362f0fc7b7fce0a64d05b56c5b28d5c2b4@164.92.209.72:36347,d24ee4b38c1ead082a7bcf8006617b640d3f5ab9@91.196.166.13:26656,5d0f0bc1c2d60f1d273165c5c8cefc3965c3d3c9@65.108.233.175:26656,5a70fdcf1f51bb38920f655597ce5fc90b8b88b8@136.244.29.116:41656,35af92154fdb2ac19f3f010c26cca9e5c175d054@65.108.238.61:27656,e65c2e27ea06b795a25f3ce813ed2062371705b8@213.239.212.121:13657,f6d0d3ac0c748a343368705c37cf51140a95929b@146.59.81.204:36657"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.kujira/config/config.toml

# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${KUJIRA_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${KUJIRA_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${KUJIRA_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${KUJIRA_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${KUJIRA_PORT}660\"%" $HOME/.kujira/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${KUJIRA_PORT}317\"%; s%^address = \":8080\"%address = \":${KUJIRA_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${KUJIRA_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${KUJIRA_PORT}091\"%" $HOME/.kujira/config/app.toml

# config pruning

pruning="custom"
echo -e "\e[1m\e[32m2. Here you will configure the pruning settings for your node, it is recommended to set your own values... \e[0m" && sleep 1
read -p "How many blocks would you like to keep (hit enter for pruning_keep_recent = 119) :" pruning_keep_recent
pruning_keep_recent=${pruning_keep_recent:-119}
read -p "How many blocks would you like to keep every (hit enter for pruning_keep_every = 0) :" pruning_keep_every
pruning_keep_every=${pruning_keep_every:-0}
read -p "How many blocks would you like to prune every (hit enter for pruning_interval=17) :" pruning_interval
pruning_interval=${pruning_interval:-17}

sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.kujira/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.kujira/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.kujira/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.kujira/config/app.toml

# config gas denoms
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.00119ukuji,0.00150factory\/kujira1qk00h5atutpsv900x202pxx42npjr9thg58dnqpa72f2p7m2luase444a7\/uusk,0.00150ibc\/295548A78785A1007F232DE286149A6FF512F180AF5657780FC89C009E2C348F,0.000125ibc\/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2,0.00126ibc\/47BD209179859CDE4A2806763D7189B6E6FE13A17880FE2B42DE1E6C1E329E23,0.00652ibc\/3607EB5B5E64DD1C0E12E07F077FF470D5BC4706AFCBC98FE1BA960E5AE4CE07,617283951ibc\/F3AA7EF362EC5E791FE78A0F4CCC69FEE1F9A7485EB1A8CAB3F6601C00522F10,0.000288ibc\/EFF323CC632EC4F747C61BCE238A758EFDB7699C3226565F7C20DA06509D59A5,0.000125ibc\/DA59C009A0B3B95E0549E6BF7B075C8239285989FF457A8EDDBB56F10B2A6986,0.00137ibc\/A358D7F19237777AF6D8AD0E0F53268F8B18AE8A53ED318095C14D6D7F3B2DB5,0.0488ibc\/4F393C3FCA4190C0A6756CE7F6D897D5D1BE57D6CCB80D0BC87393566A7B6602,78492936ibc\/004EBF085BBED1029326D56BE8A2E67C08CECE670A94AC1947DF413EF5130EB2,964351ibc\/1B38805B1C75352B28169284F96DF56BDEBD9E8FAC005BDCC8CF0378C82AA8E7\"/;" $HOME/.kujira/config/app.toml

# config timeout commit
sed -i "s/^timeout_commit *=.*/timeout_commit = \"1500ms\"/;" $HOME/.kujira/config/config.toml

# config some peers
sed -i 's/^seeds =.*/seeds = "63158c2af0d639d8105a8e6ca2c53dc243dd156f@seed.kujira.mintserve.org:31897,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:18656"/' $HOME/.kujira/config/config.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.kujira/config/config.toml

# reset
kujirad tendermint unsafe-reset-all --home $HOME/.kujira

# STATE SYNC
echo -e "\e[1m\e[32m2. Initiating State Sync... \e[0m" 
echo '================================================='&& sleep 3

RPC=https://rpc-kujira.mintthemoon.xyz:443
LATEST_HEIGHT=$(curl -s $RPC/block | jq -r .result.block.header.height)
TRUST_HEIGHT=$((LATEST_HEIGHT - 2000))
TRUST_HASH=$(curl -s "$RPC/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$RPC,$RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$TRUST_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$HOME/.kujira/config/config.toml"

kujirad start --halt-height $LATEST_HEIGHT

echo -e "\e[1m\e[32m2. Restoring previous config toml... \e[0m" 
echo '================================================='&& sleep 3
mv $HOME/.kujira/config/config.toml.bak $HOME/.kujira/config/config.toml

# END OF STATE SYNC

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 3


#Install and setup Cosmovisor

go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@latest

export DAEMON_NAME=kujirad
export DAEMON_HOME=$HOME/.kujira
source ~/.profile

mkdir -p $DAEMON_HOME/cosmovisor/genesis/bin
mkdir -p $DAEMON_HOME/cosmovisor/upgrades

cp $HOME/go/bin/kujirad $DAEMON_HOME/cosmovisor/genesis/bin

# create service
sudo tee /etc/systemd/system/cosmovisor.service > /dev/null <<EOF

[Unit]
Description=cosmovisor
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=kujirad"
Environment="DAEMON_HOME=$HOME/.kujira"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target

EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable cosmovisor
sudo systemctl restart cosmovisor

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u cosmovisor -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[32mcurl -s localhost:${KUJIRA_PORT}657/status | jq .result.sync_info\e[0m"
