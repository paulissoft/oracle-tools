def config_file = 'oracle-tools-config-development'
def maven = 'maven-3'

pipeline {
    agent any
    options {
        skipDefaultCheckout()
    }
    stages {
        stage("process") {
            steps {
                configFileProvider(
                    [configFile(fileId: config_file, variable: 'SETTINGS')]) {
                    script {
                        def props = readProperties file: env.SETTINGS // from Pipeline Utility Plugin
                        
                        env.scm_branch = props.scm_branch
                        env.scm_credentials = props.scm_credentials
                        env.scm_url = props.scm_url
                        env.scm_username = props.scm_username
                        env.scm_email = props.scm_email
                        env.conf_dir = props.conf_dir
                        env.db = props.db
                        env.db_credentials = props.db_credentials
                        env.db_dir = props.db_dir
                        env.db_actions = props.db_actions
                        env.apex_dir = props.apex_dir
                        env.apex_actions = props.apex_actions
                    }

                    withCredentials([usernamePassword(credentialsId: env.db_credentials, passwordVariable: 'db_password', usernameVariable: 'db_username')]) {
                        dir('check-out') {
                            // Clean before build
                            cleanWs()                
								            git branch: env.scm_branch, credentialsId: env.scm_credentials, url: env.scm_url

                            withMaven(maven: maven) {
                                sh("""
echo processing DB actions ${env.db_actions} in ${env.db_dir}
cd ${env.db_dir}
set ${env.db_actions}
for profile; do mvn -Ddb.config.dir=${env.conf_dir} -Ddb=${env.db} -Ddb.username=${env.db_username} -Ddb.password=${env.db_password} -P\${profile}; done
cd -

echo processing APEX actions ${env.apex_actions} in ${env.apex_dir}
cd ${env.apex_dir}
set ${env.apex_actions}
for profile; do mvn -Ddb.config.dir=${env.conf_dir} -Ddb=${env.db} -Ddb.username=${env.db_username} -Ddb.password=${env.db_password} -P\${profile}; done
cd -

git config user.name ${env.scm_username}
git config user.email ${env.scm_email}
git add .
git commit -m'Triggered Build: ${env.BUILD_NUMBER}'
git push --set-upstream origin ${env.scm_branch}
                                """)
                            }
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
