#!/data/data/com.termux/files/usr/bin/sh -e

# Optionally install SSH keys from a supplied list of GITHUB_USERS (or use arguments to this script to enumerate these)
GITHUB_USERS=${GITHUB_USERS:-$@}

# Install dependencies
which bash > /dev/null 2>&1 || yes | pkg install -y bash
which curl > /dev/null 2>&1 || yes | pkg install -y curl
which git > /dev/null 2>&1 || yes | pkg install -y git
which rsync > /dev/null 2>&1 || yes | pkg install -y rsync
which sshd > /dev/null 2>&1 || yes | pkg install -y openssh
which tor > /dev/null 2>&1 || yes | pkg install -y tor
which ipfs > /dev/null 2>&1 || yes | pkg install -y ipfs
which tsocks > /dev/null 2>&1 || yes | pkg install -y tsocks
which npm > /dev/null 2>&1 || yes | pkg install -y nodejs
#which ssb-server > /dev/null 2>&1 || yes | npm install --no-optional -g ssb-server
# Install ssb-server dependencies
npm cache verify
npm i npm@latest -g
pkg install python2
pkg install libtool
pkg install autoconf
pkg install automake
pkg install build-essentials
pkg install python-pip

# Install 14.1.12 version of ssb-server so that plugins still function
npm i ssb-server@14.1.2
ssb-server start

# Install essential ssb-server plugins
sbot plugins.install ssb-private
sbot plugins.install ssb-device-address
sbot plugins.install ssb-identities
sbot plugins.install ssb-peer-invites

# Connect to celehner's hub to get ssb-npm-registry
sbot gossip.connect ssb.celehner.com:8008~shs:5XaVcAJ5DklwuuIkjGz4lwm2rOnMHHovhNg7BFFnyJ8

# Install ssb-npm-registry
sbot plugins.install ssb-npm-registry --from 'http://localhost:8989/blobs/get/&2afFvk14JEObC047kYmBLioDgMfHe2Eg5/gndSjPQ1Q=.sha256';
sbot plugins.enable ssb-npm-registry;

# Restart ssb-server
ssb-server restart;

# Install ssb-npm tools
npm install --registry=http://localhost:8043/ -g ssb-npm;

# INSTALL GIT-SSB
ssb-npm install --global git-ssb;

# Subscribe to git-ssb polytope

# Install cabal chat
which cabal > /dev/null 2>&1 || yes | npm install --no-optional -g cabal

if [ -n "$GITHUB_USERS" ]; then

  # Add ssh keys from github user ianblenke
  mkdir -p .ssh
  touch $HOME/.ssh/authorized_keys
  (
    cat $HOME/.ssh/authorized_keys
    for user in $GITHUB_USERS; do
      curl -sL https://github.com/${user}.keys
    done
  ) | sort > $HOME/.ssh/authorized_keys.new
  mv $HOME/.ssh/authorized_keys.new ~/.ssh/authorized_keys
  chmod 700 $HOME/.ssh
  chmod 600 $HOME/.ssh/authorized_keys

fi

if [ ! -d "$HOME/termux-tor-ssh" ]; then
  git clone https://github.com/ianblenke/termux-tor-ssh $HOME/termux-tor-ssh
fi

cd $HOME/termux-tor-ssh
git pull
rsync -SHPaxq .bash_profile $HOME/.bash_profile
rsync -SHPaxq .sv/ $HOME/.sv
rsync -SHPaxq usr/ $HOME/../usr/
rsync -SHPaxq bin/ $HOME/bin/

export SVDIR=$HOME/.sv

if [ ! -d "$HOME/.ipfs" ]; then
  ipfs init
fi

mkdir -p $HOME/../usr/var/lib/tor/ssh

sv up tor
sv up sshd
sv up ipfs
sv up ssb

if [ -f $HOME/../usr/var/lib/tor/ssh/hostname ]; then
  cat $HOME/../usr/var/lib/tor/ssh/hostname
fi

echo Now restart termux and make sure everything is happy.

