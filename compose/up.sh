#!/usr/bin/env bash

REPO=$1
BRANCH=$2

git ls-remote "$REPO" &>-
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to read from '$REPO'"
    rm -
    exit 1;
fi
rm -

docker-compose down
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to turn down old containers"
    exit 1;
fi

rm -rf laravel
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to remove old source code"
    exit 1;
fi

git clone ${REPO} laravel
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to clone from '$REPO'"
    exit 1;
fi

if [ -z "$BRANCH" ]; then
    echo "[INFO] no any branch gave, using master."
else
    BRANCH=$2
    cd laravel
    git checkout ${BRANCH}
    if [ "$?" -ne 0 ]; then
        echo "[FATAL] Unable to checkout given branch: '$BRANCH', exiting"
        exit 1;
    fi
    cd ..
fi

cp -f ./.env.example ./laravel/.env

rm -f ./laravel/*.lock

echo "[INFO] finished preparing source code."

echo "[INFO] building containers"
docker-compose build
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to build containers"
    exit 1;
fi

echo "[INFO] startup containers"
docker-compose up -d
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to start containers up"
    exit 1;
fi

run() {
    docker-compose exec cgi "$@"
}

run chmod -R 777 /var/www/storage/

run chmod -R 777 /var/www/bootstrap/cache/


cd laravel

composer () {
    tty=
    tty -s && tty=--tty
    docker run \
        ${tty} \
        --interactive \
        --rm \
        --user $(id -u):$(id -g) \
        --volume /etc/passwd:/etc/passwd:ro \
        --volume /etc/group:/etc/group:ro \
        --volume $(pwd):/app \
        composer "$@"
}
echo "[INFO] installing dependences"
composer install
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to install"
    exit 1;
fi

cd -
echo "[INFO] PWD: '$PWD'"

echo "[INFO] generating key"
run php artisan key:generate
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to generate key"
    exit 1;
fi

echo "[INFO] optimizing"
run php artisan optimize
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to optimize"
    exit 1;
fi

echo "[INFO] migrating"
run php artisan migrate --seed
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Unable to migrate"
    exit 1;
fi

exit 0