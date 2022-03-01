def checkout_subdir = 'oracle-tools'

pipeline {
    agent any
    options {
        skipDefaultCheckout()
    }
    stages {
        stage("process") {
            steps {
                configFileProvider(
                    [configFile(fileId: 'oracle-tools-config-development', variable: 'SETTINGS')]) {
                    script {
                        def props = readProperties file: env.SETTINGS
                        env.scm_branch = props.scm_branch
                        env.scm_credentials = props.scm_credentials
                        env.scm_url = props.scm_url
                        // env.conf_dir
                        // env.db
                        // env.db_credentials
                        // env.db_dir
                        // env.db_actions
                        // env.apex_dir
                        // env.apex_actions
                    }

                    // withCredentials([usernamePassword(credentialsId: env.scm_credentials, passwordVariable: 'password', usernameVariable: 'username')]) { // some block }
                    
                    dir(checkout_subdir) {
                        // Clean before build
                        cleanWs()                
								        git branch: env.scm_branch, credentialsId: env.scm_credentials, url: env.scm_url
/*
                        withMaven(maven: 'maven-3') {
                            sh("""
set -eux
set
ls -l
cd ${WORKSPACE}/${checkout_subdir}/${pom_dir}
# set db-info db-install db-code-check db-test db-generate-ddl-full
set db-info db-install db-generate-ddl-full
for profile; do mvn -Ddb.config.dir=${WORKSPACE}/${checkout_subdir}/${db_config_dir} -Ddb=${db} -Ddb.host=${db_host} -Ddb.username=${db_username} -Ddb.password=${db_password} -P\${profile}; done
                            """)
                        }
                         */
                    }
                }
            }
        }
/*
        stage("check-in") {
            steps {
                sh("""
cd ${WORKSPACE}/${checkout_subdir}
git config user.name 'paulissoft'
git config user.email 'paulissoft@gmail.com'
git add .
git commit -m'Triggered Build: ${env.BUILD_NUMBER}'
git push --set-upstream origin ${branch}
                """)
            }
        }
*/
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
