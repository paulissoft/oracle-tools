// -*- mode: groovy; coding: utf-8 -*-
void call(app_env){
    script {
        assert pipelineConfig.scm_url_oracle_tools != null : "The pipeline configuration must contain a global value for 'scm_url_oracle_tools'"

        assert pipelineConfig.scm_branch_oracle_tools != null : "The pipeline configuration must contain a global value for 'scm_branch_oracle_tools'"

        env.SCM_BRANCH = app_env.scm_branch
        assert env.SCM_BRANCH != null : "The pipeline configuration must contain a value for 'scm_branch' in application environment ${app_env.long_name}"

        env.SCM_BRANCH_PREV = ( app_env.scm_branch_prev != null ? app_env.scm_branch_prev : ( app_env.previous != null ? app_env.previous.scm_branch : '' ) )

        env.SCM_CREDENTIALS = ( app_env.scm_credentials != null ? app_env.scm_credentials : pipelineConfig.scm_credentials )
        assert env.SCM_CREDENTIALS != null : "The pipeline configuration must contain a global value for 'scm_credentials' or a value in application environment ${app_env.long_name}"

        env.SCM_URL = ( app_env.scm_url != null ? app_env.scm_url : pipelineConfig.scm_url )
        assert env.SCM_URL != null : "The pipeline configuration must contain a global value for 'scm_url' or a value in application environment ${app_env.long_name}"

        // It must be possible to specify the SCM username and email as environment variables in Jenkins configuration.
        // https://github.com/paulissoft/oracle-tools/issues/70
        if ( app_env.scm_username != null ) {
            env.SCM_USERNAME = app_env.scm_username
        } else if ( pipelineConfig.scm_username != null ) {
            env.SCM_USERNAME = pipelineConfig.scm_username
        }
        assert env.SCM_USERNAME != null : "The pipeline configuration must contain a global value for 'scm_username' or a value in application environment ${app_env.long_name} or it must be defined as an environment variable SCM_USERNAME"
        if ( app_env.scm_email != null ) {
            env.SCM_EMAIL = app_env.scm_email
        } else if ( pipelineConfig.scm_email != null ) {
            env.SCM_EMAIL = pipelineConfig.scm_email
        }
        assert env.SCM_EMAIL != null : "The pipeline configuration must contain a global value for 'scm_email' or a value in application environment ${app_env.long_name} or it must be defined as an environment variable SCM_EMAIL"
        
        env.CONF_DIR = ( app_env.conf_dir != null ? app_env.conf_dir : pipelineConfig.conf_dir )
        assert env.CONF_DIR != null : "The pipeline configuration must contain a global value for 'conf_dir' or a value in application environment ${app_env.long_name}"

        env.DB = app_env.db
        assert env.DB != null : "The pipeline configuration must contain a value for 'db' in application environment ${app_env.long_name}"

        env.DB_CREDENTIALS = app_env.db_credentials
        assert env.DB_CREDENTIALS != null : "The pipeline configuration must contain a value for 'db_credentials' in application environment ${app_env.long_name}"

        env.DB_DIR = ( app_env.db_dir != null ? app_env.db_dir : pipelineConfig.db_dir )
        assert env.DB_DIR != null : "The pipeline configuration must contain a global value for 'db_dir' or a value in application environment ${app_env.long_name}"

        env.DB_ACTIONS = app_env.db_actions
        assert env.DB_ACTIONS != null : "The pipeline configuration must contain a global value for 'db_actions' or a value in application environment ${app_env.long_name}"

        env.APEX_DIR = ( app_env.apex_dir != null ? app_env.apex_dir : pipelineConfig.apex_dir )
        assert env.APEX_DIR != null : "The pipeline configuration must contain a global value for 'apex_dir' or a value in application environment ${app_env.long_name}"

        env.APEX_ACTIONS = app_env.apex_actions
        assert env.APEX_ACTIONS != null : "The pipeline configuration must contain a value for 'apex_actions' in application environment ${app_env.long_name}"
    }
    
    withCredentials([usernamePassword(credentialsId: env.DB_CREDENTIALS, passwordVariable: 'DB_PASSWORD', usernameVariable: 'DB_USERNAME')]) {
        // Clean before build
        cleanWs()

        dir('oracle-tools') {
            checkout([
                $class: 'GitSCM', 
                branches: [[name: '*/' + pipelineConfig.scm_branch_oracle_tools]], 
                doGenerateSubmoduleConfigurations: false, 
                extensions: [[$class: 'CleanCheckout']], 
                submoduleCfg: [], 
                userRemoteConfigs: [[url: pipelineConfig.scm_url_oracle_tools]]
            ])
        }

        script {
            if (pipelineConfig.scm_url_config != null && pipelineConfig.scm_branch_config != null) {
                dir('config') {
                    if (pipelineConfig.scm_credentials_config != null) {
                        git url: pipelineConfig.scm_url_config, branch: pipelineConfig.scm_branch_config, credentialsId: pipelineConfig.scm_credentials_config
                    } else {
                        git url: pipelineConfig.scm_url_config, branch: pipelineConfig.scm_branch_config
                    }
                }
            }
        }
        
        dir('myproject') {
            git branch: env.SCM_BRANCH, credentialsId: env.SCM_CREDENTIALS, url: env.SCM_URL

            withMaven(maven: pipelineConfig.maven,
                      options: [artifactsPublisher(disabled: true), 
                                findbugsPublisher(disabled: true), 
                                openTasksPublisher(disabled: true)]) {
                sshagent([env.SCM_CREDENTIALS]) {
                    sh('chmod +x $WORKSPACE/oracle-tools/jenkins/process.sh')
                    sh('$WORKSPACE/oracle-tools/jenkins/process.sh')
                }
            }
        }
    }
}
