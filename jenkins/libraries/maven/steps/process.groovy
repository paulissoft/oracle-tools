// -*- mode: groovy; coding: utf-8 -*-
void call(app_env){
    pipeline {
        agent any
        options {
            skipDefaultCheckout()
        }
        stages {
            stage("process") {
                steps {
                    script {
                        env.maven = app_env.maven
                        assert env.maven != null
                        env.scm_branch = app_env.scm_branch
                        assert env.scm_branch != null
                        env.scm_credentials = app_env.scm_credentials
                        assert env.scm_credentials != null
                        env.scm_url = app_env.scm_url
                        assert env.scm_url != null
                        env.scm_username = app_env.scm_username
                        assert env.scm_username != null
                        env.scm_email = app_env.scm_email
                        assert env.scm_email != null
                        env.conf_dir = app_env.conf_dir
                        assert env.conf_dir != null
                        env.db = app_env.db
                        assert env.db != null
                        env.db_credentials = app_env.db_credentials
                        assert env.db_credentials != null
                        env.db_dir = app_env.db_dir
                        assert env.db_dir != null
                        env.db_actions = app_env.db_actions
                        assert env.db_actions != null
                        env.apex_dir = app_env.apex_dir
                        assert env.apex_dir != null
                        env.apex_actions = app_env.apex_actions
                        assert env.apex_actions != null
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
set -x
pwd
DB_CONFIG_DIR=`cd ${conf_dir} && pwd`
# for Jenkins pipeline
## ORACLE_TOOLS_DIR="$WORKSPACE@script/`ls -rt $WORKSPACE@script | grep -v 'scm-key.txt' | tail -1`"
# for Jenkins Templating Engine
ORACLE_TOOLS_DIR=$WORKSPACE
echo processing DB actions ${db_actions} in ${db_dir} with configuration directory $DB_CONFIG_DIR
set -- ${db_actions}
for PROFILE; do mvn -f ${db_dir} -Doracle-tools.dir=$ORACLE_TOOLS_DIR -Ddb.config.dir=$DB_CONFIG_DIR -Ddb=${db} -Ddb.username=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$PROFILE; done

echo processing APEX actions ${apex_actions} in ${apex_dir} with configuration directory $DB_CONFIG_DIR
set -- ${apex_actions}
for PROFILE; do mvn -f ${apex_dir} -Doracle-tools.dir=$ORACLE_TOOLS_DIR -Ddb.config.dir=$DB_CONFIG_DIR -Ddb=${db} -Ddb.username=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$PROFILE; done

git config user.name ${scm_username}
git config user.email ${scm_email}
git add .
! git commit -m"Triggered Build: $BUILD_NUMBER" || git push --set-upstream origin ${scm_branch}
                            ''')
                        }
                    }
                }
            }
        }
        post {
            // Clean after build
            always {
                cleanWs(cleanWhenNotBuilt: false,
                        deleteDirs: true,
                        disableDeferredWipeout: true,
                        notFailBuild: true,
                        patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                                   [pattern: '.propsfile', type: 'EXCLUDE']])
            }
        }
    }
}
