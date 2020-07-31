# Terminate execution if any command fails
set -e

start=$(date +%s)

SSH_KEY_PATH="" # like ~/dev/ssh/mykey
SERVER="" # like root@1.1.1.1
DEST_FOLDER="" # like /home/admin/web/example.com/public_html
USER="admin"

PARAMS="USER=\"$USER\" DEST_FOLDER=\"$DEST_FOLDER\""

echo ===================================================
echo Autodeploy server
echo ===================================================
echo build
yarn run build
echo build finished
echo ===================================================
echo compress build files
mv build buildnew
tar -czf build.tar.gz buildnew
rm -rf buildnew
echo compress build files finished
echo ===================================================
echo upload build files
# scp -i $SSH_KEY_PATH build.tar.gz $SERVER:$DEST_FOLDER
rsync -Pav -e "ssh -i $SSH_KEY_PATH" build.tar.gz $SERVER:$DEST_FOLDER
rm -f build.tar.gz
echo upload build files finished
echo ===================================================
echo Connecting to remote server...
ssh -i $SSH_KEY_PATH $SERVER $PARAMS 'bash -i' <<-'ENDSSH'
    #Connected
    # Terminate execution if any command fails
	set -e

    su $USER

    cd $DEST_FOLDER

    tar -xzf  build.tar.gz

    if [ -f build ]; then
       mv build buildold
    fi
    mv buildnew/ build
    rm -rf buildold/
    rm -f build.tar.gz

    chown -R $USER:$USER $(pwd)
    find $(pwd) -type d -exec chmod 775 {} \;
    find $(pwd) -type f -exec chmod 664 {} \;

    exit
ENDSSH

end=$(date +%s)

runtime=$((end - start))
echo deploy took $runtime seconds
