pipeline {
    agent any
    stages {
        stage("Tag and Push") {
            environment { 
                GIT_TAG = "jenkins-$BUILD_NUMBER"
            }
            steps {
								git branch: 'development',
    								credentialsId: 'fd87b3b8-8972-4889-be8d-86342abacb22',
    								url: 'git@github.com:paulissoft/oracle-tools.git'
		
                sh('''
                    git config user.name 'paulissoft'
                    git config user.email 'paulissoft@gmail.com'
                    git tag -a \$GIT_TAG -m "[Jenkins CI] New Tag"
                    git push origin \$GIT_TAG
                ''')
            }
        }
    }
}
