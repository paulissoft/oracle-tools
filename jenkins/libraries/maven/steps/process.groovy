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

                    withCredentials([usernamePassword(credentialsId: env.db_credentials, passwordVariable: 'db_password', usernameVariable: 'db_username')]) {
                        // Clean before build
                        cleanWs()                
                        git branch: env.scm_branch, credentialsId: env.scm_credentials, url: env.scm_url

                        withMaven(maven: maven,
                                  options: [artifactsPublisher(disabled: true), 
                                            findbugsPublisher(disabled: true), 
                                            openTasksPublisher(disabled: true)]) {
                            sh('''
pwd
db_config_dir=`cd $conf_dir && pwd`
oracle_tools_dir="$WORKSPACE@script/`ls -rt $WORKSPACE@script | grep -v 'scm-key.txt' | tail -1`"
echo processing DB actions $db_actions in $db_dir with configuration directory $db_config_dir
set -- $db_actions
for profile; do mvn -f $db_dir -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=$db -Ddb.username=$db_username -Ddb.password=$db_password -P$profile; done

echo processing APEX actions $apex_actions in $apex_dir with configuration directory $db_config_dir
set -- $apex_actions
for profile; do mvn -f $apex_dir -Doracle-tools.dir=$oracle_tools_dir -Ddb.config.dir=$db_config_dir -Ddb=$db -Ddb.username=$db_username -Ddb.password=$db_password -P$profile; done

git config user.name $scm_username
git config user.email $scm_email
git add .
! git commit -m"Triggered Build: $BUILD_NUMBER" || git push --set-upstream origin $scm_branch
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
