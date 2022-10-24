#!/bin/bash -e

# start a subshell to set -x and run the command
function x() { (set -x; "$@") } 

export -f x

file1=/home/jenkins/agent/workspace/test1.txt
dir1=$(dirname $file1)
file2=/home/jenkins/.m2/repository/test2.txt
dir2=$(dirname $file2)

if [ $# -eq 0 ]
then
    set -- 0 1 2 3 1 4 1
fi

for step
do
    echo "=== step $step ==="
    case $step in
        0) echo "Removing text files on jenkins_nfs_server"
           x docker exec --interactive --tty --user root jenkins_nfs_server bash -c 'rm -f /nfs/*/test*.txt || true'
           echo ""
           ;;
        1) echo "Showing user jenkins on each container"
           for c in jenkins_nfs_server jenkins_nfs_client
           do
               x docker exec --interactive --tty --user root $c id jenkins
           done
           for item in root:jenkins_nfs_server:/nfs/workspace \
                           root:jenkins_nfs_server:/nfs/repository \
                           jenkins:jenkins_nfs_client:$dir1 \
                           jenkins:jenkins_nfs_client:$dir2
           do
               user=$(echo $item | cut -d ':' -f 1)
               container=$(echo $item | cut -d ':' -f 2)
               dir=$(echo $item | cut -d ':' -f 3)
               echo "$user@$container:$dir (first 10 files/folders)"
               echo ""
               docker exec --interactive --tty --user $user $container bash -c "find $dir | head -10"
               echo ""
           done
           ;;
        2) echo "Trying to touch a file on jenkins_nfs_client as root: this must FAIL"
           ! x time docker exec --interactive --tty --user root jenkins_nfs_client touch $file1 || exit 1
           ! x time docker exec --interactive --tty --user root jenkins_nfs_client touch $file2 || exit 1
           echo ""
           ;;
        3) echo "Trying to touch a file on jenkins_nfs_client as user: this must be OK"
           x docker exec --interactive --tty --user jenkins jenkins_nfs_client touch $file1
           x docker exec --interactive --tty --user jenkins jenkins_nfs_client touch $file2
           echo ""
           ;;
        4) echo "Removing test files from jenkins_nfs_client"
           x docker exec --interactive --tty --user jenkins jenkins_nfs_client bash -c "rm -f $file1"
           x docker exec --interactive --tty --user jenkins jenkins_nfs_client bash -c "rm -f $file2"
           echo ""
           ;;
        *) echo "Unknown step" 1>&2
           exit 1
           ;;
    esac
done

echo "=== the END ==="
