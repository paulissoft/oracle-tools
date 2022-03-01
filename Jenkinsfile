def branch = 'development'
def credentialsId = 'fd87b3b8-8972-4889-be8d-86342abacb22'
def url = 'git@github.com:paulissoft/oracle-tools.git'
def db = 'orcl'
def db_username = 'oracle_tools'
def db_password = 'oracle_tools'
def pom_dir = 'db/app'

pipeline {
    agent any
    stages {
        stage("check-out") {
            steps {
								git branch: branch,
    								credentialsId: credentialsId,
    								url: url
						}
				}

        stage("build") {
            steps {
                withMaven(maven: 'maven-3') {
                    sh("""
                        cd ${pom_dir}
                        pwd
                        set -x
                        mvn -Ddb=${db} -Ddb.username=${db_username} -Ddb.password=${db_password} -Pdb-info
                        mvn -Ddb=${db} -Ddb.username=${db_username} -Ddb.password=${db_password} -Pdb-install
                        mvn -Ddb=${db} -Ddb.username=${db_username} -Ddb.password=${db_password} -Pdb-code-test
                        mvn -Ddb=${db} -Ddb.username=${db_username} -Ddb.password=${db_password} -Pdb-test
                        mvn -Ddb=${db} -Ddb.username=${db_username} -Ddb.password=${db_password} -Pdb-generate-ddl-full
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
