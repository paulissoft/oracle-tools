pipeline {
    agent any
    stages {
        stage("Tag and Push") {
            when { branch 'development' }
            environment { 
                GIT_TAG = "jenkins-$BUILD_NUMBER"
            }
            steps {
                sh('''
                    git config user.name 'paulissoft'
                    git config user.email 'paulissoft@gmail.com'
                    git tag -a \$GIT_TAG -m "[Jenkins CI] New Tag"
                ''')
                
                sshagent(['fd87b3b8-8972-4889-be8d-86342abacb22']) {
                    sh("""
                        #!/usr/bin/env bash
                        set +x
                        export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
                        git push origin \$GIT_TAG
                     """)
                }
            }
        }
    }
}
