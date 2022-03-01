
cd /var/jenkins_home/workspace/dev/add_tag@tmp
git config user.name paulissoft
git config user.email paulissoft@gmail.com
git add .
git commit -m'Triggered Build: 38'
git push --set-upstream origin development
                