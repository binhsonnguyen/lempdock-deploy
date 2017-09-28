#!/usr/bin/env bash

git pull
if [ "$?" -ne 0 ]; then
    echo "[FATAL] Could not self-update, exiting"
    exit 1;
fi

REPO=$1
git ls-remote "$REPO" &>-
if [ "$?" -ne 0 ]; then
    echo "[ERROR] Unable to read from '$REPO'"
    rm -
    exit 1;
fi
rm -

if [[ "$(docker images -q codegym/php7-fpm 2> /dev/null)" == "" ]]; then
    echo "[FUCK] php7-fpm image not found, building one"
    cd ./php7-prebuild/
    ./build.sh
    if [ "$?" -ne 0 ]; then
        echo "[FATAL] Unable to build php7-fpm image, exit"
        exit 1;
    fi
    echo "[INFO] php7-fpm build successfully"
    cd ..
fi

LOWER_PORT=4000
UPPER_PORT=4999
LOWER_DB_PORT=24000
UPPER_DB_PORT=24999

COUNTER=0

PORT=$(shuf -i ${LOWER_PORT}-${UPPER_PORT} -n 1)
echo "[INFO] finding a port for deploy web container"
while :; do
    (echo "" >/dev/tcp/127.0.0.1/${PORT}) >/dev/null 2>&1
    if [ $? -ne 0 ] && [  ! -f ".$PORT.lock" ]; then
        touch ".$PORT.lock"
        COUNTER=0
        echo "[INFO] $PORT"
        break 2
    fi

    if [ "$COUNTER" -gt "9" ]; then
        echo "[FUCK] I can't find any port, exiting"
        exit 1
    fi

    echo "[INFO] port $PORT used, finding another"
    PORT=$(shuf -i ${LOWER_PORT}-${UPPER_PORT} -n 1)
    ((COUNTER++))
done

DB_PORT=$(shuf -i ${LOWER_DB_PORT}-${UPPER_DB_PORT} -n 1)
echo "[INFO] finding a port for deploy database container"
while :; do
    (echo "" >/dev/tcp/127.0.0.1/${DB_PORT}) >/dev/null 2>&1
    if [ $? -ne 0 ] && [  ! -f ".$DB_PORT.lock" ]; then
        echo ${DB_PORT} > ".$PORT.lock"
        touch ".$DB_PORT.lock"
        echo "[INFO] $DB_PORT"
        break 2
    fi

    if [ "$COUNTER" -gt "9" ]; then
        echo "[FUCK] I can't find any port, exiting"
        exit 1
    fi

    echo "[INFO] port $DB_PORT used, finding another"
    DB_PORT=$(shuf -i ${LOWER_DB_PORT}-${UPPER_DB_PORT} -n 1)
    ((COUNTER++))
done

echo "[ERROR] creating an app root folder"
mkdir ${PORT}
if [ $? -ne 0 ]; then
    echo "[ERROR] can not create directory $PORT, exiting"
    ./down.sh ${PORT}
fi
echo "$PORT"

echo "[INFO] copying needed files"

cp -v ./compose/docker-compose.yml "./$PORT/"
cp -v ./compose/cgi.dockerfile "./$PORT/"
cp -v ./compose/web.dockerfile "./$PORT/"
cp -v ./compose/.env.example "./$PORT/"
cp -v ./compose/vhost.conf "./$PORT/"
cp -v ./compose/up.sh "./$PORT/"

cd ${PORT}

echo "[INFO] manipulating contents"

sed -i "s/\$WEB_PORT/$PORT/g" docker-compose.yml
sed -i "s/\$DB_PORT/$DB_PORT/g" docker-compose.yml
sed -i "s/\$WEB_PORT/$PORT/g" .env.example
sed -i "s/\$DB_PORT/$DB_PORT/g" .env.example

echo "[INFO] please give sudo password for next steps"

echo "[INFO] openning port ${PORT}"
sudo firewall-cmd --permanent --add-port=${PORT}/tcp
if [ $? -ne 0 ]; then
    echo "[ERROR] can not open port $PORT, exiting"
    ./down.sh ${PORT}
fi

echo "[INFO] openning port ${DB_PORT}"
sudo firewall-cmd --permanent --add-port=${DB_PORT}/tcp
if [ $? -ne 0 ]; then
    echo "[ERROR] can not open port $DB_PORT, exiting"
    ./down.sh ${PORT}
fi

echo "[INFO] reloading firewalld"
sudo firewall-cmd --reload
if [ $? -ne 0 ]; then
    echo "[ERROR] can not reload firewalld, exiting"
    ./down.sh ${PORT}
fi

./up.sh ${REPO}
if [ "$?" -ne 0 ]; then
    echo "[FUCK]"
    cd -
    ./down.sh ${PORT}
    exit 1;
fi

echo "[FUCK] $REPO deployed at $PORT, DB port: $DB_PORT"