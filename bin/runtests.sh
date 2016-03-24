#!/bin/bash

DB=mysql
OCWD=`pwd`
BUNDLE=""
SYMFONY__DATABASE__DRIVER=${SYMFONY__DATABASE__DRIVER:-mysql}
SYMFONY__PHPCR__TRANSPORT=${SYMFONY__PHPCR__TRANSPORT:-doctrine_dbal}
JACKRABBIT_RESTART=false

source "$(dirname "$0")""/inc/runtestcommon.inc.sh"

function error {
    echo ""
    echo -e "\x1b[31m======================================================\x1b[0m"
    echo $1
    echo -e "\x1b[31m======================================================\x1b[0m"
    echo ""
}

function init_database {
    comment "> initializing database"

    init_dbal

    if [[ $SYMFONY__PHPCR__TRANSPORT == 'doctrine_dbal' ]]; then
        init_phpcr_dbal
    fi

    php vendor/symfony-cmf/testing/bin/console sulu:document:initialize
}

function show_help {
    echo "Sulu Test Runner"
    echo ""
    echo "Usage:"
    echo ""
    echo "  ./bin/runtests.sh -i -a # initialize and run all tests"
    echo "  ./bin/runtests.sh -t LocationBundle # run only LocationBundle tests"
    echo ""
    echo "Options:"
    echo ""
    echo "  i) Execute the initializaction script before running the tests"
    echo "  t) Specify a target bundle"
    echo "  a) Run all tests"
    echo "  r) restart jackrabbit between bundle tests"
    exit 0
}

function init_dbal {
    info "Creating database"
    php vendor/symfony-cmf/testing/bin/console doctrine:database:create

    if [[ $? != 0 ]]; then
        comment "> database already exists"
        php vendor/symfony-cmf/testing/bin/console doctrine:schema:update --force
    else
        echo "Creating schema"
        php vendor/symfony-cmf/testing/bin/console doctrine:schema:create
    fi

}

function init_phpcr_dbal {
    echo "Initialzing PHPCR (including doctrine-dbal, this may fail)"
    php vendor/symfony-cmf/testing/bin/console doctrine:phpcr:init:dbal &> /dev/null
}

logo

header "Sulu CMF Test Suite"
comment "DB Driver: "$SYMFONY__DATABASE__DRIVER
comment "PHPCR Transport: "$SYMFONY__PHPCR__TRANSPORT

while getopts ":ait:r" OPT; do
    case $OPT in
        i)
            init_database
            ;;
        t)
            BUNDLE=$OPTARG
            ;;
        a)
            ;;
        r)
            JACKRABBIT_RESTART=true
            ;;
    esac
done

if [[ -z $1 ]]; then
    show_help
fi

if [ -e /tmp/failed.tests ]; then
    rm /tmp/failed.tests
fi

touch /tmp/failed.tests

if [ -z $BUNDLE ]; then
    BUNDLES=`find ./src/Sulu/Bundle/* -maxdepth 1 -name "phpunit.xml.dist"`
else
    BUNDLES=`find ./src/Sulu/Bundle/$BUNDLE -maxdepth 1 -name "phpunit.xml.dist"`
fi

for BUNDLE in $BUNDLES; do

    BUNDLE_DIR=`dirname $BUNDLE`
    BUNDLE_NAME=`basename $BUNDLE_DIR`

    header $BUNDLE_NAME

    cd $BUNDLE_DIR

    if [ ! -e vendor ]; then
        ln -s $OCWD"/vendor" vendor
    fi

    if [[ ! -z "$KERNEL_DIR" ]]; then
        CONSOLE="env KERNEL_DIR=$OCWD"/"$KERNEL_DIR $OCWD/bin/console"
        comment "> kernel: "$KERNEL_DIR

        $CONSOLE container:debug | cut -d' ' -f2 | grep "^doctrine.orm" &> /dev/null \
            && comment "> doctrine ORM detected" \
            && $CONSOLE doctrine:schema:update --force
    fi

    comment "> running preparation script"
    BEFORE_SCRIPT="bin/before-test.sh"
    if [ -e $BEFORE_SCRIPT ]; then
        bash $BEFORE_SCRIPT
    fi

    comment "> running tests"

    phpunit -c phpunit.xml.dist

    if [ $? -ne 0 ]; then
        echo $BUNDLE_NAME >> /tmp/failed.tests
    fi

    cd -

    if [ "$JACKRABBIT_RESTART" = true ] ; then
        echo ""
        comment "> restarting jackrabbit"

        PID=`ps -ef | grep "jackrabbit-standalone" | grep -v grep | awk '{ print $2 }'`
        if [ $PID ]; then
            kill -9 $PID
        fi

        ./bin/jackrabbit.sh
    fi
done

check_failed_tests
