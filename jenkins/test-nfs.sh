#!/bin/bash -e

# start a subshell to set -x and run the command
function x() { (set -x; "$@") } 

! printenv DEBUG 1>/dev/null || set -x

export -f x

file1=/home/jenkins/agent/workspace/test1.txt
dir1=$(dirname $file1)
file2=/home/jenkins/.m2/repository/test2.txt
dir2=$(dirname $file2)

if [ $# -eq 0 ]
then
    set -- 0 1 2 3 1 4 1
fi

docker run --name jenkins_agent --rm -d -it -v jenkins-agent-workspace:/home/jenkins/agent/workspace -v jenkins-m2-repository:/home/jenkins/.m2/repository ghcr.io/paulissoft/pato-jenkins-agent:latest sleep 3600

jenkins_nfs_server=jenkins_nfs_server
jenkins_agents=jenkins_agent

for step
do
    echo "=== step $step ==="
    case $step in
        0) echo "Removing text files on $jenkins_nfs_server"
           x docker exec --interactive --tty --user root $jenkins_nfs_server bash -c 'rm -f /nfs/*/test*.txt || true'
           echo ""
           ;;
        1) for f in /etc/exports /etc/hosts.allow /etc/hosts.deny
           do
               echo "--- root@$jenkins_nfs_server:$f ---"
               echo ""
               docker exec --interactive --tty --user root $jenkins_nfs_server cat $f
               echo ""
           done
           for c in $jenkins_nfs_server $jenkins_agents
           do
               echo "--- id of user jenkins on container $c ---"
               echo ""
               docker exec --interactive --tty --user root $c id jenkins
               echo ""
           done
           items="root:$jenkins_nfs_server:/nfs/workspace root:$jenkins_nfs_server:/nfs/repository"
           for c in $jenkins_agents
           do
               items="$items jenkins:$c:$dir1 jenkins:$c:$dir2"
           done
           for item in $items
           do
               user=$(echo $item | cut -d ':' -f 1)
               container=$(echo $item | cut -d ':' -f 2)
               dir=$(echo $item | cut -d ':' -f 3)
               echo "--- $user@$container:$dir (first 10 files/folders) ---"
               echo ""
               docker exec --interactive --tty --user $user $container bash -c "find $dir | head -10"
               echo ""
           done
           ;;
        2) for jenkins_agent in $jenkins_agents
           do
               echo "Trying to touch a file on $jenkins_agent as root: this must FAIL"           
               ! x docker exec --interactive --tty --user root $jenkins_agent touch $file1 || exit 1
               ! x docker exec --interactive --tty --user root $jenkins_agent touch $file2 || exit 1
               echo ""
           done
           ;;
        3) for jenkins_agent in $jenkins_agents
           do
               echo "Trying to touch a file on $jenkins_agent as user: this must be OK"           
               x docker exec --interactive --tty --user jenkins $jenkins_agent touch $file1
               x docker exec --interactive --tty --user jenkins $jenkins_agent touch $file2
               echo ""
           done
           ;;
        4) for jenkins_agent in $jenkins_agents
           do
               echo "Removing test files from $jenkins_agent"           
               x docker exec --interactive --tty --user jenkins $jenkins_agent bash -c "rm -f $file1"
               x docker exec --interactive --tty --user jenkins $jenkins_agent bash -c "rm -f $file2"
               echo ""
           done
           ;;
        *) echo "Unknown step" 1>&2
           exit 1
           ;;
    esac
done

docker stop jenkins_agent

echo "=== the END ==="
