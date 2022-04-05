// -*- mode: groovy; coding: utf-8 -*-
void call(app_env){
    stage(app_env.short_name) {
        steps {
            script {
                env.MAVEN = app_env.maven
                assert env.MAVEN != null
                env.SCM_BRANCH = app_env.scm_branch
                assert env.scm_branch != null
                env.SCM_BRANCH_PREV = ( app_env.previous != null ? app_env.previous.scm_branch : '' )
                env.SCM_CREDENTIALS = app_env.scm_credentials
                assert env.SCM_CREDENTIALS != null
                env.SCM_URL = app_env.scm_url
                assert env.SCM_URL != null
                env.SCM_USERNAME = app_env.scm_username
                assert env.SCM_USERNAME != null
                env.SCM_EMAIL = app_env.scm_email
                assert env.SCM_EMAIL != null
                env.CONF_DIR = app_env.conf_dir
                assert env.CONF_DIR != null
                env.DB = app_env.db
                assert env.DB != null
                env.DB_CREDENTIALS = app_env.db_credentials
                assert env.DB_CREDENTIALS != null
                env.DB_DIR = app_env.db_dir
                assert env.DB_DIR != null
                env.DB_ACTIONS = app_env.db_actions
                assert env.DB_ACTIONS != null
                env.APEX_DIR = app_env.apex_dir
                assert env.APEX_DIR != null
                env.APEX_ACTIONS = app_env.apex_actions
                assert env.APEX_ACTIONS != null
            }
                    
            withCredentials([usernamePassword(credentialsId: app_env.db_credentials, passwordVariable: 'DB_PASSWORD', usernameVariable: 'DB_USERNAME')]) {
                // Clean before build
                cleanWs()                
                git branch: app_env.scm_branch, credentialsId: app_env.scm_credentials, url: app_env.scm_url

                withMaven(maven: app_env.maven,
                          options: [artifactsPublisher(disabled: true), 
                                    findbugsPublisher(disabled: true), 
                                    openTasksPublisher(disabled: true)]) {
                    sh('''
git config user.name ${SCM_USERNAME}
git config user.email ${SCM_EMAIL}
test -z "$SCM_BRANCH_PREV" || git merge "$SCM_BRANCH_PREV"

db_config_dir=`cd ${CONF_DIR} && pwd`
# for Jenkins pipeline
## oracle_tools_dir="$WORKSPACE@script/`ls -rt $WORKSPACE@script | grep -v 'scm-key.txt' | tail -1`"
# for Jenkins Templating Engine
oracle_tools_dir=$WORKSPACE

# First DB run
echo "processing DB actions ${DB_ACTIONS} in ${DB_DIR} with configuration directory $db_config_dir"
set -- ${DB_ACTIONS}
for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -Ddb.username=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile; done
if [ -n "$(git status --porcelain)" ]
then
  git add .
  git commit -m"Database changes. Triggered Build: $BUILD_NUMBER"
  git push --set-upstream origin ${SCM_BRANCH}
fi

# Second DB run: verify that there are no changes after a second round (just install and generate DDL)
DB_ACTIONS="db-install db-generate-ddl-full"
echo "checking that there are no changes after a second round of ${DB_ACTIONS} (standard output is suppressed)"
set -- ${DB_ACTIONS}
for profile; do mvn -f ${DB_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -Ddb.username=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile 1>/dev/null; done
echo "there should be no files to add for Git:"
test -z "$(git status --porcelain)"

echo "processing APEX actions ${APEX_ACTIONS} in ${APEX_DIR} with configuration directory $db_config_dir"
set -- ${APEX_ACTIONS}
for profile; do mvn -f ${APEX_DIR} -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=${DB} -Ddb.username=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$profile; done
# ${APEX_DIR}/src/export/application/create_application.sql changes its p_flow_version
create_application=${APEX_DIR}/src/export/application/create_application.sql
git update-index --assume-unchanged    $create_application
workspace_changed=$(git status --porcelain)
git update-index --no-assume-unchanged $create_application
if [ -n "$workspace_changed" ]
then
  git add .
  git commit -m"APEX changes. Triggered Build: $BUILD_NUMBER"
  git push --set-upstream origin ${SCM_BRANCH}
fi
                    ''')
                }
            }
        }
    }
}
