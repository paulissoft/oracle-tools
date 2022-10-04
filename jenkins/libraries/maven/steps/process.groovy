// -*- mode: groovy; coding: utf-8 -*-

def is_empty(String value) {
    return value == null || value.equals("")
}

def show_env(app_env, pipelineConfig, env) {
    String[] properties = [ 'scm_url_oracle_tools'
                           ,'scm_branch_oracle_tools'
                           ,'scm_project_oracle_tools'
                           ,'scm_url_config'
                           ,'scm_branch_config'
                           ,'scm_credentials_config'
                           ,'scm_project_config'
                           ,'conf_dir'
                           ,'db'
                           ,'db_credentials'
                           ,'db_dir'
                           ,'db_actions'
                           ,'apex_dir'
                           ,'apex_actions'
                           ,'scm_username'
                           ,'scm_email'
                           ,'scm_branch'
                           ,'scm_branch_prev'
                           ,'scm_credentials'
                           ,'scm_url'
                           ,'scm_project'
    ]

    for (String property in properties.sort()) {
        String v = app_env.getProperty(property)
        
        if (!is_empty(v)) {
            println "app_env.$property = " + v
        }
    }
    pipelineConfig.sort().each{k, v -> if (properties.contains(k) && !is_empty(v)) { println "pipelineConfig.$k = $v" }}
    env.getEnvironment().sort().each{k, v -> if (properties.contains(k.toLowerCase()) && !is_empty(v)) { println "env.$k = $v" }}
}

def set_env(app_env, pipelineConfig, env, String key, Boolean mandatory=true, Integer level=3, String default_value=null) {
    String value = app_env[key]
    String KEY = key.toUpperCase()
    
    if (is_empty(value) && level > 1) {
        value = pipelineConfig[key]

        if (is_empty(value) && level > 2) {
            value = env[KEY]
        }
    }

    if ( is_empty(value) ) {
        value = default_value
    }

    if (mandatory) {
        String error;

        switch(level) {
            case 3:
                error = "Either application environment '${app_env.long_name}' variable 'app_env.${key}' or " +
                    "pipeline configuration variable 'pipelineConfig.${key}' or " +
                    "environment variable 'env.${KEY}' must be a non-empty string"
                break
            case 2:
                error = "Either application environment '${app_env.long_name}' variable 'app_env.${key}' or " +
                    "pipeline configuration variable 'pipelineConfig.${key}' must be a non-empty string"
                break
            case 1:
                error = "Application environment '${app_env.long_name}' variable 'app_env.${key}' must be a non-empty string"
                break
            default:
                assert level >= 1 && level <= 3: "Level must be between 1 and 3"
        }
        
        assert !is_empty(value) : error
    }

    println "env.$KEY = $value"
    
    return value
}
        
void call(app_env){
    script {
        show_env(app_env, pipelineConfig, env)
        
        /*
        -- The SCM Oracle Tools project needed to build the SCM project
        */

        env.SCM_URL_ORACLE_TOOLS = set_env(app_env, pipelineConfig, env, 'scm_url_oracle_tools', false)
        env.SCM_BRANCH_ORACLE_TOOLS = set_env(app_env, pipelineConfig, env, 'scm_branch_oracle_tools', !is_empty(env.SCM_URL_ORACLE_TOOLS)) // mandatory if the URL is there
        if (!is_empty(env.SCM_URL_ORACLE_TOOLS)) {
            String name = env.SCM_URL_ORACLE_TOOLS.substring(env.SCM_URL_ORACLE_TOOLS.lastIndexOf("/") + 1).replaceAll("\\.git\$", "")
            
            env.SCM_PROJECT_ORACLE_TOOLS = set_env(app_env, pipelineConfig, env, 'scm_project_oracle_tools', true, 3, name)
        }
        
        /*
        -- The SCM (database) configuration project needed to build the SCM project
        */

        env.SCM_URL_CONFIG = set_env(app_env, pipelineConfig, env, 'scm_url_config', false)
        env.SCM_BRANCH_CONFIG = set_env(app_env, pipelineConfig, env, 'scm_branch_config', !is_empty(env.SCM_URL_CONFIG)) // mandatory if the URL is there
        env.SCM_CREDENTIALS_CONFIG = set_env(app_env, pipelineConfig, env, 'scm_credentials_config', false)
        if (!is_empty(env.SCM_URL_CONFIG)) {
            String name = env.SCM_URL_CONFIG.substring(env.SCM_URL_CONFIG.lastIndexOf("/") + 1).replaceAll("\\.git\$", "")
            
            env.SCM_PROJECT_CONFIG = set_env(app_env, pipelineConfig, env, 'scm_project_config', true, 3, name)
        }
        
        /*
        -- The configuration directory to work on
        */
        
        env.CONF_DIR = set_env(app_env, pipelineConfig, env, 'conf_dir')

        /*
        -- The database info to work on
        */
        
        env.DB = set_env(app_env, pipelineConfig, env, 'db', true, 1)
        env.DB_CREDENTIALS = set_env(app_env, pipelineConfig, env, 'db_credentials', true, 1) // application environment specific
        env.DB_DIR = set_env(app_env, pipelineConfig, env, 'db_dir')
        env.DB_ACTIONS = set_env(app_env, pipelineConfig, env, 'db_actions', false, 2, '') // application environment or pipeline configuration specific

        /*
        -- The APEX info to work on
        */
        
        env.APEX_DIR = set_env(app_env, pipelineConfig, env, 'apex_dir')
        env.APEX_ACTIONS = set_env(app_env, pipelineConfig, env, 'apex_actions', false, 2, '') // application environment or pipeline configuration specific
        
        /*
        -- SCM credentials username and e-mail
        */
        
        // It must be possible to specify the SCM username and email as environment variables in Jenkins configuration.
        // https://github.com/paulissoft/oracle-tools/issues/70
        Boolean credentials_needed = (env.DB_ACTIONS =~ /\bdb-generate-ddl-full\b/) || (env.APEX_ACTIONS =~ /\bapex-export\b/)
        
        env.SCM_USERNAME = set_env(app_env, pipelineConfig, env, 'scm_username', credentials_needed)
        env.SCM_EMAIL = set_env(app_env, pipelineConfig, env, 'scm_email', credentials_needed)

        /*
        -- The SCM project to work on
        */
        
        env.SCM_BRANCH = set_env(app_env, pipelineConfig, env, 'scm_branch', true, 1)
        env.SCM_BRANCH_PREV = set_env(app_env, pipelineConfig, env, 'scm_branch_prev', false, 1, ( app_env.previous != null ? app_env.previous.scm_branch : '' ))
        env.SCM_CREDENTIALS = set_env(app_env, pipelineConfig, env, 'scm_credentials', credentials_needed)
        env.SCM_URL = set_env(app_env, pipelineConfig, env, 'scm_url', true)
        env.SCM_PROJECT = set_env(app_env, pipelineConfig, env, 'scm_project', true, 3, env.SCM_URL.substring(env.SCM_URL.lastIndexOf("/") + 1).replaceAll("\\.git\$", ""))
    }
    
    withCredentials([usernamePassword(credentialsId: env.DB_CREDENTIALS, passwordVariable: 'DB_PASSWORD', usernameVariable: 'DB_USERNAME')]) {
        // Clean before build
        cleanWs()

        // checkout of (optional) configuration project (maybe credentials needed)
        script {
            // skip checkout if the configuration project is the same as project            
            if (!is_empty(env.SCM_PROJECT_CONFIG) &&
                !env.SCM_PROJECT_CONFIG.equals(env.SCM_PROJECT)) {
                echo "Checking out configuration project ${env.SCM_URL_CONFIG} to ${env.SCM_PROJECT_CONFIG} with credentials ${env.SCM_CREDENTIALS_CONFIG}" 
                dir(env.SCM_PROJECT_CONFIG) {
                    if (!is_empty(env.SCM_CREDENTIALS_CONFIG)) {
                        git url: env.SCM_URL_CONFIG, branch: env.SCM_BRANCH_CONFIG, credentialsId: env.SCM_CREDENTIALS_CONFIG
                    } else {
                        checkout([
                            $class: 'GitSCM', 
                            branches: [[name: '*/' + env.SCM_BRANCH_CONFIG]], 
                            doGenerateSubmoduleConfigurations: false, 
                            extensions: [[$class: 'CleanCheckout']], 
                            submoduleCfg: [], 
                            userRemoteConfigs: [[url: env.SCM_URL_CONFIG]]
                        ])
                    }
                }
            }
        
            // checkout of (optional) Oracle Tools (no credentials needed)

            // skip checkout if the Oracle Tools project is the same as the (configuration) project
            if (!is_empty(env.SCM_PROJECT_ORACLE_TOOLS) &&
                (is_empty(env.SCM_PROJECT)        || !env.SCM_PROJECT_ORACLE_TOOLS.equals(env.SCM_PROJECT)) &&
                (is_empty(env.SCM_PROJECT_CONFIG) || !env.SCM_PROJECT_ORACLE_TOOLS.equals(env.SCM_PROJECT_CONFIG))) {
                echo "Checking out Oracle Tools project ${env.SCM_URL_ORACLE_TOOLS} to ${env.SCM_PROJECT_ORACLE_TOOLS} without credentials"
                dir(env.SCM_PROJECT_ORACLE_TOOLS) {
                    checkout([
                        $class: 'GitSCM', 
                        branches: [[name: '*/' + env.SCM_BRANCH_ORACLE_TOOLS]], 
                        doGenerateSubmoduleConfigurations: false, 
                        extensions: [[$class: 'CleanCheckout']], 
                        submoduleCfg: [], 
                        userRemoteConfigs: [[url: env.SCM_URL_ORACLE_TOOLS]]
                    ])
                }
            }

            // checkout of (mandatory) project to build (maybe credentials needed)

            echo "Checking out build project ${env.SCM_URL} to ${env.SCM_PROJECT} with credentials ${env.SCM_CREDENTIALS}" 
            dir(env.SCM_PROJECT) {
                if (!is_empty(env.SCM_CREDENTIALS)) {                    
                    git url: env.SCM_URL, branch: env.SCM_BRANCH, credentialsId: env.SCM_CREDENTIALS
                } else {
                    checkout([
                        $class: 'GitSCM', 
                        branches: [[name: '*/' + env.SCM_BRANCH]], 
                        doGenerateSubmoduleConfigurations: false, 
                        extensions: [[$class: 'CleanCheckout']], 
                        submoduleCfg: [], 
                        userRemoteConfigs: [[url: env.SCM_URL]]
                    ])
                }

                withMaven(options: [artifactsPublisher(disabled: true), 
                                    findbugsPublisher(disabled: true), 
                                    openTasksPublisher(disabled: true)]) {
                    sh('chmod +x $WORKSPACE/oracle-tools/jenkins/process.sh')
                    if (!is_empty(env.SCM_CREDENTIALS)) {
                        sshagent([env.SCM_CREDENTIALS]) {
                            sh('$WORKSPACE/oracle-tools/jenkins/process.sh')
                        }
                    } else {
                        sh('$WORKSPACE/oracle-tools/jenkins/process.sh')
                    }
                }
            }
        }
    }
}
