!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://raw.githubusercontent.com/cryptology-nodes/main/main/logo.sh |  bash && sleep 2


if [ ! $REBUS_NODENAME ]; then
read -p "Enter node name: " REBUS_NODENAME
echo 'export REBUS_NODENAME='\"${REBUS_NODENAME}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update
sudo apt install make clang pkg-config libssl-dev build-essential git jq ncdu bsdmainutils htop -y < "/dev/null"

echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
wget -O go1.18.4.linux-amd64.tar.gz https://golang.org/dl/go1.18.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.4.linux-amd64.tar.gz && rm go1.18.4.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
rm -rf $HOME/rebus 
git clone https://github.com/rebuschain/rebus.core.git 
cd rebus.core && git checkout testnet
make build
mv $HOME/rebus.core/build/rebusd /usr/local/bin/
sleep 1
rebusd init "$REBUS_NODENAME" --chain-id=reb_3333-1
PEER="1ae3fe91ec7aba98eba3aa472453a92aa0a38c04@116.202.169.22:28656,289b378944a9983dc7f6ed6b09ba4a30d8290ee1@148.251.53.155:28656,f2cf370ecff71c0e95b0970f3b2821ea11b66a40@195.201.165.123:20106,1f40e130d2c21a32b0d678eabddc45ec3d6964a2@138.201.127.91:26674,82fc54cd4f7cbb44ee5e9d0565d40b5b29475974@88.198.242.163:46656,bdb21276daf5cc3672ddf5597c68c61dc44ec8e5@212.154.90.211:21656,bcf1b8d1896031da70f5bd1d634d10591d066b1c@5.161.128.219:28656,8abcf4cbdfa413f310e792f31aa54e82e9e09a0c@38.242.131.51:26656,eb47d2414351c010c8f747701f184cf3f8a30181@79.143.179.196:16656,f084e8960bb714c3446796cb4738e78bc5c3f04b@65.109.18.179:31656,34dde0a9cac6aeecc3e6570b59a0d297ab64f5bd@65.108.126.46:31656,d5c87b9a13a3d5be1456e9d982c1fc0fe71d8723@38.242.156.72:26656,d4ac8ea1bc083d6348997fda833ffcf5b150bd92@38.242.156.132:26656,d1a72df36686394e99ff0fff006d58f042692699@161.97.136.177:21656,c2368a4db640aa26fb8d5bc9d0f331758d42ca86@141.95.65.26:28656,9f601f082beb325abf3b6b08cdf27374c8a29469@38.242.206.198:56656,64f998cfa053619f1c755fdb6b7e431ae7c0c7b3@95.217.89.23:30530"
sed -i.bak "s/^persistent_peers *=.*/persistent_peers = \"$PEER\"/;" $HOME/.rebusd/config/config.toml
#PRUNING CONFIG
sed -i "s/pruning *=.*/pruning = \"custom\"/g" $HOME/.rebusd/config/app.toml
sed -i "s/pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/g" $HOME/.rebusd/config/app.toml
sed -i "s/pruning-interval *=.*/pruning-interval = \"10\"/g" $HOME/.rebusd/config/app.toml
sed -i.bak -e "s/indexer *=.*/indexer = \"null\"/g" $HOME/.rebusd/config/config.toml
wget -O $HOME/.rebusd/config/genesis.json https://raw.githubusercontent.com/rebuschain/rebus.testnet/master/rebus_3333-1/genesis.json
rebusd tendermint unsafe-reset-all
echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1

echo "[Unit]
Description=Rebus Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which rebusd) start
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/rebusd.service
sudo mv $HOME/rebusd.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable rebusd
sudo systemctl restart rebusd

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service rebusd status | grep active` =~ "running" ]]; then
  echo -e "Your rebus node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice rebusd status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your rebus node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
