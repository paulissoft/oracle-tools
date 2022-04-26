// -*- mode: groovy; coding: utf-8 -*-
void call(app_env){
    script {
        assert pipelineConfig.maven != null
        assert pipelineConfig.jdk != null
        assert pipelineConfig.scm_url_oracle_tools != null
        assert pipelineConfig.scm_branch_oracle_tools != null
        assert pipelineConfig.scm_url != null
        assert pipelineConfig.scm_credentials != null
        assert pipelineConfig.scm_username != null
        assert pipelineConfig.scm_email != null
        assert pipelineConfig.conf_dir != null
        assert pipelineConfig.db_dir != null
        assert pipelineConfig.apex_dir != null
        
        env.SCM_BRANCH = app_env.scm_branch
        assert env.SCM_BRANCH != null
        env.SCM_BRANCH_PREV = ( app_env.previous != null ? app_env.previous.scm_branch : '' )
        env.SCM_CREDENTIALS = ( app_env.scm_credentials != null ? app_env.scm_credentials : pipelineConfig.scm_credentials )
        assert env.SCM_CREDENTIALS != null
        env.SCM_URL = ( app_env.scm_url != null ? app_env.scm_url : pipelineConfig.scm_url )
        assert env.SCM_URL != null
        env.SCM_USERNAME = ( app_env.scm_username != null ? app_env.scm_username : pipelineConfig.scm_username )
        assert env.SCM_USERNAME != null
        env.SCM_EMAIL = ( app_env.scm_email != null ? app_env.scm_email : pipelineConfig.scm_email )
        assert env.SCM_EMAIL != null

        env.CONF_DIR = ( app_env.conf_dir != null ? app_env.conf_dir : pipelineConfig.conf_dir )
        assert env.CONF_DIR != null

        env.DB = app_env.db
        assert env.DB != null
        env.DB_CREDENTIALS = app_env.db_credentials
        assert env.DB_CREDENTIALS != null
        env.DB_DIR = ( app_env.db_dir != null ? app_env.db_dir : pipelineConfig.db_dir )
        assert env.DB_DIR != null
        env.DB_ACTIONS = app_env.db_actions
        assert env.DB_ACTIONS != null
        env.DB_USERNAME_PROPERTY = ( app_env.db_username_property != null ? app_env.db_username_property : 'db.proxy.username' )        

        env.APEX_DIR = ( app_env.apex_dir != null ? app_env.apex_dir : pipelineConfig.apex_dir )
        assert env.APEX_DIR != null
        env.APEX_ACTIONS = app_env.apex_actions
        assert env.APEX_ACTIONS != null
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
        
        dir('myproject') {
            git branch: env.SCM_BRANCH, credentialsId: env.SCM_CREDENTIALS, url: env.SCM_URL

            withMaven(maven: pipelineConfig.maven,
                      options: [artifactsPublisher(disabled: true), 
                                findbugsPublisher(disabled: true), 
                                openTasksPublisher(disabled: true)]) {
                sshagent([env.SCM_CREDENTIALS]) {
                    sh('chmod +x $WORKSPACE/oracle-tools/jenkins/process.sh && $WORKSPACE/oracle-tools/jenkins/process.sh')
                }
            }
        }
    }
}
