pipeline {
    def branch = 'development'
    def credentialsId = 'fd87b3b8-8972-4889-be8d-86342abacb22'
    def url = 'git@github.com:paulissoft/oracle-tools.git'
    def db = 'orcl'
    def db_username = 'oracle_tools'
    def db_password = 'oracle_tools'
    def profiles = ["db-info", "db-install", "db-code-test", "db-test", "db-generate-ddl-full"]
    def pom_file = 'db/app/pom.xml'

    agent any
    stages {
        stage("check-out") {
            steps {
								git branch: branch,
    								credentialsId: credentialsId,
    								url: url
						}
				}

        for (profile in profiles) {
            stage(profile) {
                steps {
                    withMaven {
                        sh "mvn -f ${pom_file} -Ddb=${db} -Ddb.username=${db_username} -Ddb.password=${db_password} -P${profile}"
                    }
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
