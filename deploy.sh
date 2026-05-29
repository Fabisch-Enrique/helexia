#!/bin/bash
export MIX_ENV=prod
export $(grep -v '^#' /etc/helexia/helexia.conf | xargs)

eval "$(ssh-agent -s)"

branch=$1 || 'dev'
git reset --hard || exit 1
git checkout $branch || exit 1
git pull || exit 1
echo "Running deployment for branch $(git rev-parse --short HEAD)"

cd ~/helexia-web/ || exit 1
npm i --prefix assets

mix deps.get --only prod
mix compile
mix sentry_recompile
mix assets.build
mix assets.deploy
mix phx.digest
mix ecto.migrate -r Helexia.Repo || exit 1

mkdir -p ~/releases
MIX_ENV=prod mix release --path ~/releases/helexia_new --overwrite --force || (echo "Failed due to app compilation" && exit 1)

mkdir -p ~/releases/helexia_bk
sudo mkdir -p /rel/helexia

sudo rm -rf ~/releases/helexia_bk &&
    sudo mv /rel/helexia ~/releases/helexia_bk &&
    sudo mv ~/releases/helexia_new /rel/helexia

if  compgen -G /rel/helexia/helexia*.tar.gz; then
    sudo mv /rel/helexia/helexia*.tar.gz ~/releases/
fi

if [[ -f /etc/systemd/system/helexia.service ]]; then
    echo "Daemon service already installed"
else
    sudo cp /rel/helexia/helexia.service /etc/systemd/system/helexia.service
    sudo systemctl daemon-reload
    echo "Daemon service installed"
fi

/rel/helexia/bin/helexia eval "Helexia.Release.seed"

sudo systemctl restart helexia.service
if [[ $(systemctl show -p SubState helexia.service) = "SubState=running" ]]; then
    echo "Application is up and running"
else
    echo "Application is not running" && exit 1
    sudo rm -rf ~/releases/helexia_failed
    sudo mv /rel/helexia ~/releases/helexia_failed
    sudo mv ~/releases/helexia_bk /rel/helexia
    sudo systemctl restart helexia.service
    echo 'Failed to start Helexia, restoring previous build'
    exit 1
fi
