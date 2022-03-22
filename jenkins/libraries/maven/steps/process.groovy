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
                    configFileProvider(
                        [configFile(fileId: app_env.config_file, variable: 'SETTINGS')]) {
                        script {
                            def props = readProperties file: env.SETTINGS // from Pipeline Utility Plugin

                            env.scm_branch = props.scm_branch
                            assert env.scm_branch != null
                            env.scm_credentials = props.scm_credentials
                            assert env.scm_credentials != null
                            env.scm_url = props.scm_url
                            assert env.scm_url != null
                            env.scm_username = props.scm_username
                            assert env.scm_username != null
                            env.scm_email = props.scm_email
                            assert env.scm_email != null
                            env.conf_dir = props.conf_dir
                            assert env.conf_dir != null
                            env.db = props.db
                            assert env.db != null
                            env.db_credentials = props.db_credentials
                            assert env.db_credentials != null
                            env.db_dir = props.db_dir
                            assert env.db_dir != null
                            env.db_actions = props.db_actions
                            assert env.db_actions != null
                            env.apex_dir = props.apex_dir
                            assert env.apex_dir != null
                            env.apex_actions = props.apex_actions
                            assert env.apex_actions != null
                        }

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
