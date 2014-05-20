#!/bin/bash

HOST="deploy@goslow4.me"
APP_DIR=/home/deploy/apps/goslow4me
LOG_DIR=$APP_DIR/log
CURRENT_DIR=$APP_DIR/current
DESTINATION_DIR=$APP_DIR/releases/`date +%Y-%m-%d-%H-%M-%S`

function over_ssh_do(){
  COMMAND=$@
  ssh $HOST "$COMMAND"
  if [ $? -ne 0 ]; then
      echo "Failed to run: '$COMMAND'"
      exit 1
  fi
}

function rsync_project(){
  rsync -a -v --exclude=node_modules --exclude=.git -e "ssh" . $HOST:$DESTINATION_DIR
  if [ $? -ne 0 ]; then
      exit 1
  fi
}

echo "creating directories"
over_ssh_do "mkdir -p $APP_DIR/releases $APP_DIR/log $APP_DIR/forever"
echo "starting rsync"
rsync_project
echo "npm install"
over_ssh_do "cd $DESTINATION_DIR && npm install --production"
echo "linking current"
over_ssh_do "ln -nsf $DESTINATION_DIR $CURRENT_DIR"
echo "Restarting Service"

over_ssh_do "forever restart \
  -l $LOG_DIR/forever.log \
  -o $LOG_DIR/goslow4me.log \
  -e $LOG_DIR/goslow4me.log \
  --append \
  -p $APP_DIR/forever \
  -c coffee $CURRENT_DIR/src/application.coffee"


echo "Deployed."
