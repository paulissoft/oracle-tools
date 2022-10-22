#!/bin/bash -e

# start a subshell to set -x and run the command
function x() { (set -x; "$@") } 

export -f x

file1=/home/jenkins/agent/workspace/test1.txt
dir1=$(dirname $file1)
file2=/home/jenkins/.m2/repository/test2.txt
dir2=$(dirname $file2)
oracle_tools_dir=$(dirname $0)/..

if [ $# -ne 0 ]
then
    set -- $*
else
    set -- 0 1 2 3 1 4 1
fi

for step
do
    echo "=== step $step ==="
    case $step in
        0) echo "Removing text files on jenkins_nfs_server"
           x docker exec --interactive --tty jenkins_nfs_server bash -c 'rm -f /nfs/*/test*.txt || true'
           echo ""
           ;;
        1) echo "Showing contents of jenkins_nfs_server"
           x docker exec --interactive --tty jenkins_nfs_server bash -c 'find /nfs'
           echo ""
           echo "Showing contents of jenkins_nfs_client"
           x docker exec --interactive --tty --user jenkins jenkins_nfs_client find $dir1 $dir2 -ls
           echo ""
           ;;
        2) echo "Trying to touch a file on jenkins_nfs_client as root: this must FAIL"
           ! x perl $oracle_tools_dir/src/scripts/timeout.pl -t 5 docker exec --interactive --tty jenkins_nfs_client touch $file1 || exit 1
           ! x perl $oracle_tools_dir/src/scripts/timeout.pl -t 5 docker exec --interactive --tty jenkins_nfs_client touch $file2 || exit 1
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
    sleep 1
done
