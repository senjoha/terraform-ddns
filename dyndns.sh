#!/bin/sh
# check if we can ping google with ipv6, else break
if ! ping -6 -c 1 ipv6.google.com &> /dev/null; then
  echo "ipv6 ping failed."
  curl -d "ipv6 ping failed." https://ntfy.iede.senjoha.org/serverstatus
  exit 1
fi

# check if we can reach ipify.org using ipv6, else break
if ! ping6 -c 1 ipv6.google.com &> /dev/null; then
  echo "ipify unavailable"
  curl -d "ipify unavailable." https://ntfy.iede.senjoha.org/serverstatus
  exit 1
fi

# get our ipv6 address from ipify.org
IPV6=$(curl -s -6 https://api64.ipify.org)

# extract the /64 bit network prefix from answer
v6prefix=$(echo $IPV6 | sed 's/^\(.\{19\}\).*/\1/')
echo $v6prefix

# get our public ipv4 address from ipify.org
IPV4=$(curl -s -4 https://api.ipify.org)
echo $IPV4

# check, if ip has changed, else exit
if [ $(dig AAAA ntfy.iede.senjoha.org +short) == $v6prefix:be24:11ff:fe8b:3e6e ] || [ $(dig A ntfy.iede.senjoha.org +short) == $IPV4 ]; then
    echo "exiting"
    exit 0;
fi

# create variabls.tf file
cat << EOF > variables.tf
variable "ipv4" {
  type = string
  default = "$IPV4"
  description = "default ipv4 address of most services"
}

variable "ipv6" {
  type = string
  default = "$v6prefix"
  description = "default ipv4 address of most services"
}
EOF

# unset all variables
unset $IPV6
unset $v6prefix
unset $IPV4

# apply the new generated terraform config
cd /home/senjoha/cloudflare-tf/
echo "running terraform plan"
terraform plan
echo "applying terraform"
terraform apply -auto-approve
cd $OLDPWD

# check if apply was successful and notify
if [ $? != 0 ]; then
    echo "error, did not apply terraform dns update!"
    curl -d "error, did not apply terraform dns update!" https://ntfy.iede.senjoha.org/serverstatus
else
    echo "dns updated successfully."
    curl -d "dns updated successfully." https://ntfy.iede.senjoha.org/serverstatus
fi
