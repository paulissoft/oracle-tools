def branch = 'development'
def credentialsId = 'fd87b3b8-8972-4889-be8d-86342abacb22'
def url = 'git@github.com:paulissoft/oracle-tools.git'
def db = 'orcl'
def db_username = 'oracle_tools'
def db_password = 'ORACLE_TOOLS'
def pom_dir = "db/app/ddl"
def db_config_dir = "conf/src"
def db_host = 'host.docker.internal'

pipeline {
    agent any
    stages {
        stage("check-out") {
            steps {
                dir('oracle-tools') {
								    git branch: branch, credentialsId: credentialsId, url: url
                }
						}
				}

        stage("build") {
            steps {
                withMaven(maven: 'maven-3') {
                    sh("""
set -eux
cd ${WORKSPACE}/oracle-tools/${pom_dir}
set db-info db-install db-code-check db-test db-generate-ddl-full
for profile; do mvn -Ddb.config.dir=${WORKSPACE}/oracle-tools/${db_config_dir} -Ddb=${db} -Ddb.host=${db_host} -Ddb.username=${db_username} -Ddb.password=${db_password} -P\${profile}; done
                    """)
                }
            }
        }

        stage("check-in") {
            steps {
                sh("""
git config user.name 'paulissoft'
git config user.email 'paulissoft@gmail.com'
git add .
git commit -m'Triggered Build: ${env.BUILD_NUMBER}'
git push origin
                """)
            }
        }
    }
}
