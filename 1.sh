sudo apt-get update
sudo apt-get install -y curl gnupg lsb-release

curl -fsSL https://openresty.org/package/pubkey.gpg | sudo tee /etc/apt/trusted.gpg.d/openresty.asc

echo "deb http://openresty.org/package/debian $(lsb_release -c | awk '{print $2}') main" | sudo tee /etc/apt/sources.list.d/openresty.list