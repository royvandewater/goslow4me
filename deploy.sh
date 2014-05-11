#!/bin/bash

HOST="deploy@goslow4.me"
APP_DIR=/home/deploy/apps/goslow4me
LOG_DIR=$APP_DIR/log
CURRENT_DIR=$APP_DIR/current
DESTINATION_DIR=$APP_DIR/releases/`date +%Y-%m-%d-%H-%M-%S`

function over_ssh_do(){
  ssh $HOST "$@"
  if [ $? -ne 0 ]; then
      exit 1
  fi
}

function rsync_project(){
  rsync -a -v --exclude=node_modules --exclude=.git -e "ssh" . $HOST:$DESTINATION_DIR
  if [ $? -ne 0 ]; then
      exit 1
  fi
}

over_ssh_do "mkdir -p $APP_DIR/releases $APP_DIR/log $APP_DIR/forever"
rsync_project
over_ssh_do "cd $DESTINATION_DIR && npm install"
over_ssh_do "ln -nsf $DESTINATION_DIR $CURRENT_DIR"
echo "forever restart \
  -l $LOG_DIR/forever.log \
  -o $LOG_DIR/goslow4me.log \
  -e $LOG_DIR/goslow4me.log \
  -p $APP_DIR/forever \
  -c coffee $CURRENT_DIR/src/application.coffee"

over_ssh_do "forever restart \
  -l $LOG_DIR/forever.log \
  -o $LOG_DIR/goslow4me.log \
  -e $LOG_DIR/goslow4me.log \
  --append \
  -p $APP_DIR/forever \
  -c coffee $CURRENT_DIR/src/application.coffee"


echo "Deployed."
