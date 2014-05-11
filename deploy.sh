#!/bin/bash

HOSTS="goslow4.me"
APP_DIR=/home/deploy/apps/goslow4me
LOG_DIR=$APP_DIR/log
CURRENT_DIR=$APP_DIR/current
DESTINATION_DIR=$APP_DIR/releases/`date +%Y-%m-%d-%H-%M-%S`
FOREVER_COMMAND="forever restart \
  -l $LOG_DIR/forever.log \
  -o $LOG_DIR/goslow4me.log \
  -e $LOG_DIR/goslow4me.log \
  -p $APP_DIR/forever
  -c coffee $APP_DIR/src/application.coffee"

function over_ssh_do(){
  ssh $HOST "$@"
  if [ $? -ne 0 ]; then
      exit 1
  fi
}

function rsync_project(){
  rsync -a -e "ssh" . $HOST:$DESTINATION_DIR
  if [ $? -ne 0 ]; then
      exit 1
  fi
}

over_ssh_do mkdir -p $APP_DIR/releases $APP_DIR/log $APP_DIR/forever
rsync_project
over_ssh_do "cd $DESTINATION_DIR && npm install && $FOREVER_COMMAND"

ssh $HOST "ln -nsf $DESTINATION_DIR $CURRENT_DIR"
if [ $? -ne 0 ]; then
    exit 1
fi

echo "Deployed."
