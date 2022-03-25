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
                        assert app_env.maven != null
                        assert app_env.scm_branch != null
                        assert app_env.scm_credentials != null
                        assert app_env.scm_url != null
                        assert app_env.scm_username != null
                        assert app_env.scm_email != null
                        assert app_env.conf_dir != null
                        assert app_env.db != null
                        assert app_env.db_credentials != null
                        assert app_env.db_dir != null
                        assert app_env.db_actions != null
                        assert app_env.apex_dir != null
                        assert app_env.apex_actions != null
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
pwd
DB_CONFIG_DIR=`cd ${app_env.conf_dir} && pwd`
ORACLE_TOOLS_DIR="$WORKSPACE@script/`ls -rt $WORKSPACE@script | grep -v 'scm-key.txt' | tail -1`"
echo processing DB actions ${app_env.db_actions} in ${app_env.db_dir} with configuration directory $DB_CONFIG_DIR
set -- ${app_env.db_actions}
for PROFILE; do mvn -f ${app_env.db_dir} -Doracle-tools.dir=$ORACLE_TOOLS_DIR -Ddb.config.dir=$DB_CONFIG_DIR -Ddb=${app_env.db} -Ddb.username=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$PROFILE; done

echo processing APEX actions ${app_env.apex_actions} in ${app_env.apex_dir} with configuration directory $DB_CONFIG_DIR
set -- ${app_env.apex_actions}
for PROFILE; do mvn -f ${app_env.apex_dir} -Doracle-tools.dir=$ORACLE_TOOLS_DIR -Ddb.config.dir=$DB_CONFIG_DIR -Ddb=${app_env.db} -Ddb.username=$DB_USERNAME -Ddb.password=$DB_PASSWORD -P$PROFILE; done

git config user.name ${app_env.scm_username}
git config user.email ${app_env.scm_email}
git add .
! git commit -m"Triggered Build: $BUILD_NUMBER" || git push --set-upstream origin ${app_env.scm_branch}
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
