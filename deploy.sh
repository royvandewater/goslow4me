#!/bin/bash
start=`date +%s`

HOST="deploy@goslow4.me"
REPO="https://github.com/royvandewater/goslow4me"
APP_DIR=/home/deploy/apps/goslow4me
LOG_DIR=$APP_DIR/log
CURRENT_DIR=$APP_DIR/current
DESTINATION_DIR=$APP_DIR/releases/`date +%Y-%m-%d-%H-%M-%S`
NPM_BIN="node_modules/.bin"

function locally_do(){
  COMMAND=$@
  $COMMAND
  if [ $? -ne 0 ]; then
      echo "Failed to run: '$COMMAND'"
      exit 1
  fi
}

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

function restart_forever(){
  over_ssh_do "forever restart \
    -l $LOG_DIR/forever.log \
    -o $LOG_DIR/goslow4me.log \
    -e $LOG_DIR/goslow4me.log \
    --append \
    -p $APP_DIR/forever \
    -c coffee $CURRENT_DIR/src/application.coffee"
}

# Rollback

if [[ ! -z $1 ]]; then
  if [ $1 == 'rollback' ]; then
    echo "Rollback"
    echo "Pointing current to last deploy"
    LATEST_DEPLOY=$(over_ssh_do "ls -t $APP_DIR/releases | head -n 1")
    PREVIOUS_DEPLOY=$(over_ssh_do "ls -t $APP_DIR/releases | head -n 2 | tail -n 1")
    over_ssh_do "ln -nsf $APP_DIR/releases/$PREVIOUS_DEPLOY $CURRENT_DIR"
    echo "Restarting forever"
    restart_forever
    echo "Moving bad release to /tmp/$LATEST_DEPLOY on remote server"
    over_ssh_do "mv $APP_DIR/releases/$LATEST_DEPLOY /tmp/$LATEST_DEPLOY"
    echo "Rolled back to: $PREVIOUS_DEPLOY"
    exit 0
  fi
fi

# Standard Deploy

echo "creating directories"
over_ssh_do "mkdir -p $APP_DIR/releases $APP_DIR/log $APP_DIR/forever"

echo "cloning git"
over_ssh_do "git clone --depth=1 $REPO $DESTINATION_DIR"

echo "npm install"
over_ssh_do "cd $DESTINATION_DIR && npm install --production"

echo "gzipping assets"
over_ssh_do "cd $DESTINATION_DIR/public && \
  for f in \$(find . -type f); do \
    gzip -9 -c \$f > \$f.gz; \
  done"

echo "linking current"
over_ssh_do "ln -nsf $DESTINATION_DIR $CURRENT_DIR"

echo "Restarting Service"
restart_forever

end=`date +%s`
runtime=$((end-start))
echo "Deployed in ${runtime} seconds"

