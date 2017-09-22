#!/usr/bin/env bash

PORT=$1

cd ${PORT}
if [ "$?" -ne 0 ]; then
    echo "[ERROR] ${PORT} not running, exit"
    exit 1;
fi

echo "[INFO] stopping container"
docker-compose down
if [ "$?" -ne 0 ]; then
    echo "[WARNING] can not stop ${PORT}"
fi
echo "[INFO] container stopped"

cd -

DB_PORT=$(cat ".$PORT.lock")

rm -rf ${PORT}
if [ "$?" -ne 0 ]; then
    echo "[WARNING] can not remove ${PORT}"
else
    echo "[INFO] ${PORT} removed"
fi

echo "please give password for close ports"

sudo firewall-cmd --permanent --remove-port=${PORT}/tcp
if [ "$?" -ne 0 ]; then
    echo "[WARNING] can not close port $PORT"
else
    echo "[INFO] port $PORT closed"

    echo "[INFO] reloading firewalld"
    sudo firewall-cmd --reload
    if [ "$?" -ne 0 ]; then
        echo "[WARNING] can not reload firewalld"
    else
        echo "[INFO] firewalld restarted"
    fi

    rm -f ".$PORT.lock"
    if [ "$?" -ne 0 ]; then
        echo "[WARNING] can not remove '.$PORT.lock'"
    else
        echo "[INFO] '.$PORT.lock' removed"
    fi

fi

sudo firewall-cmd --permanent --remove-port=${DB_PORT}/tcp
if [ "$?" -ne 0 ]; then
    echo "[WARNING] can not close port $DB_PORT"
else
    echo "[INFO] port $DB_PORT closed"

    sudo firewall-cmd --reload
    if [ "$?" -ne 0 ]; then
        echo "[WARNING] can not reload firewalld"
    else
        echo "[INFO] firewalld restarted"
    fi

    rm -f ".$DB_PORT.lock"
    if [ "$?" -ne 0 ]; then
        echo "[WARNING] can not remove '.$DB_PORT.lock'"
    else
        echo "[INFO] '.$DB_PORT.lock' removed"
    fi
fi
