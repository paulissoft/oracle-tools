// -*- mode: groovy; coding: utf-8 -*-

void call(app_env) {
    String app_env_name = app_env.name

    if (env.VERBOSE > 1) {
        println "process(${app_env})"
    }    

    script {        
        stage("${app_env_name} - setup environment") {
            show_env(app_env, pipelineConfig, env)
            
            /*
             -- The SCM PATO project needed to build the SCM project
             */

            env.SCM_URL_ORACLE_TOOLS = get_env(app_env_name, app_env, 'scm_url_oracle_tools', false)
            env.SCM_BRANCH_ORACLE_TOOLS = get_env(app_env_name, app_env, 'scm_branch_oracle_tools', !is_empty(env.SCM_URL_ORACLE_TOOLS)) // mandatory if the URL is there
            if (!is_empty(env.SCM_URL_ORACLE_TOOLS)) {
                String name = env.SCM_URL_ORACLE_TOOLS.substring(env.SCM_URL_ORACLE_TOOLS.lastIndexOf("/") + 1).replaceAll("\\.git\$", "")
                
                env.SCM_PROJECT_ORACLE_TOOLS = get_env(app_env_name, app_env, 'scm_project_oracle_tools', true, 3, name)
            }
            
            /*
             -- The SCM (database) configuration project needed to build the SCM project
             */

            env.SCM_URL_CONFIG = get_env(app_env_name, app_env, 'scm_url_config', false)
            env.SCM_BRANCH_CONFIG = get_env(app_env_name, app_env, 'scm_branch_config', !is_empty(env.SCM_URL_CONFIG)) // mandatory if the URL is there
            env.SCM_CREDENTIALS_CONFIG = get_env(app_env_name, app_env, 'scm_credentials_config', false)
            if (!is_empty(env.SCM_URL_CONFIG)) {
                String name = env.SCM_URL_CONFIG.substring(env.SCM_URL_CONFIG.lastIndexOf("/") + 1).replaceAll("\\.git\$", "")
                
                env.SCM_PROJECT_CONFIG = get_env(app_env_name, app_env, 'scm_project_config', true, 3, name)
            }
            
            /*
             -- The configuration directory to work on
             */
            
            env.CONF_DIR = get_env(app_env_name, app_env, 'conf_dir')

            /*
             -- The database info to work on
             */
            
            env.DB = get_env(app_env_name, app_env, 'db', true, 1)
            env.DB_CREDENTIALS = get_env(app_env_name, app_env, 'db_credentials', true, 1) // application environment specific
            env.DB_DIR = get_env(app_env_name, app_env, 'db_dir')
            env.DB_ACTIONS = get_env(app_env_name, app_env, 'db_actions', false, 2) // application environment or pipeline configuration specific

            /*
             -- The APEX info to work on
             */
            
            env.APEX_DIR = get_env(app_env_name, app_env, 'apex_dir')
            env.APEX_ACTIONS = get_env(app_env_name, app_env, 'apex_actions', false, 2) // application environment or pipeline configuration specific
            
            /*
             -- SCM credentials username and e-mail
             */
            
            // It must be possible to specify the SCM username and email as environment variables in Jenkins configuration.
            // https://github.com/paulissoft/oracle-tools/issues/70
            Boolean credentials_needed = (env.DB_ACTIONS =~ /\bdb-generate-ddl-full\b/) || (env.APEX_ACTIONS =~ /\bapex-export\b/)
            
            env.SCM_USERNAME = get_env(app_env_name, app_env, 'scm_username', credentials_needed)
            env.SCM_EMAIL = get_env(app_env_name, app_env, 'scm_email', credentials_needed)

            /*
             -- The SCM project to work on
             */
            
            env.SCM_BRANCH = get_env(app_env_name, app_env, 'scm_branch', true, 1)
            env.SCM_BRANCH_PREV = get_env(app_env_name, app_env, 'scm_branch_prev', false, 1, ( app_env.previous != null ? app_env.previous.scm_branch : '' ))
            env.SCM_CREDENTIALS = get_env(app_env_name, app_env, 'scm_credentials', credentials_needed)
            env.SCM_URL = get_env(app_env_name, app_env, 'scm_url', true)
            env.SCM_PROJECT = get_env(app_env_name, app_env, 'scm_project', true, 3, env.SCM_URL.substring(env.SCM_URL.lastIndexOf("/") + 1).replaceAll("\\.git\$", ""))

            // It must be possible to have a dry run for Jenkins.
            // https://github.com/paulissoft/oracle-tools/issues/84
            env.DRY_RUN = get_env(app_env_name, app_env, 'dry_run', false)
            // It must be possible to use the Maven daemon in Jenkins.
            // https://github.com/paulissoft/oracle-tools/issues/82
            env.MVN = get_env(app_env_name, app_env, 'mvn', true, 3, 'mvn')
            env.MVN_ARGS = get_env(app_env_name, app_env, 'mvn_args', false)
            env.MVN_LOG_DIR = get_env(app_env_name, app_env, 'mvn_log_dir', false)
        }
    }
    
    withCredentials([usernamePassword(credentialsId: env.DB_CREDENTIALS, passwordVariable: 'DB_PASSWORD', usernameVariable: 'DB_USERNAME')]) {
        // Clean before build
        cleanWs()

        // checkout of (optional) configuration project (maybe credentials needed)
        script {
            // skip checkout if the configuration project is the same as project            
            if (!is_empty(env.SCM_PROJECT_CONFIG) &&
                !env.SCM_PROJECT_CONFIG.equals(env.SCM_PROJECT)) {
                stage("${app_env_name} - checkout configuration project") {
                    echo "About to check-out configuration project, " +
                        "url='${env.SCM_URL_CONFIG}', " +
                        "branch='${env.SCM_BRANCH_CONFIG}', " +
                        "directory='${app_env_name}/${env.SCM_PROJECT_CONFIG}', " +
                        "credentials='${env.SCM_CREDENTIALS_CONFIG}'"
                    dir("${app_env_name}/${env.SCM_PROJECT_CONFIG}") {
                        if (env.DRY_RUN) {
                            echo "Skipping check-out since it is a dry run"
                        } else if (!is_empty(env.SCM_CREDENTIALS_CONFIG)) {
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
            }
        }
        
        // checkout of (optional) PATO (no credentials needed)
        script {
            // skip checkout if the PATO project is the same as the (configuration) project
            if (!is_empty(env.SCM_PROJECT_ORACLE_TOOLS) &&
                (is_empty(env.SCM_PROJECT)        || !env.SCM_PROJECT_ORACLE_TOOLS.equals(env.SCM_PROJECT)) &&
                (is_empty(env.SCM_PROJECT_CONFIG) || !env.SCM_PROJECT_ORACLE_TOOLS.equals(env.SCM_PROJECT_CONFIG))) {
                stage("${app_env_name} - checkout PATO project") {
                    echo "About to check-out PATO project, " +
                        "url='${env.SCM_URL_ORACLE_TOOLS}', " +
                        "branch='${env.SCM_BRANCH_ORACLE_TOOLS}', " +
                        "directory='${app_env_name}/${env.SCM_PROJECT_ORACLE_TOOLS}', " +
                        "no credentials"
                    dir("${app_env_name}/${env.SCM_PROJECT_ORACLE_TOOLS}") {
                        if (env.DRY_RUN) {
                            echo "Skipping check-out since it is a dry run"
                        } else {
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
                }
            }
        }

        // checkout of (mandatory) project to build (maybe credentials needed)
        script {
            stage("${app_env_name} - process") {
                echo "About to check-out build project, " +
                    "url='${env.SCM_URL}', " +
                    "branch='${env.SCM_BRANCH}', " +
                    "directory='${app_env_name}/${env.SCM_PROJECT}', " +
                    "credentials='${env.SCM_CREDENTIALS}'"
                dir("${app_env_name}/${env.SCM_PROJECT}") {
                    if (env.DRY_RUN) {
                        echo "Skipping check-out since it is a dry run"
                    } else if (!is_empty(env.SCM_CREDENTIALS)) {                    
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
                    
                    echo "About to execute Maven actions"
                    /*
                    withMaven(options: [artifactsPublisher(disabled: true), 
                                        findbugsPublisher(disabled: true), 
                                        openTasksPublisher(disabled: true),
                                        junitPublisher(disabled: true)]) {*/
                        if (env.DRY_RUN) {
                            echo "Skipping the execution of Maven actions since it is a dry run"
                        } else {
                            String script = "$WORKSPACE/${app_env_name}/${env.SCM_PROJECT}/jenkins/process.sh"
                            
                            if (!is_empty(env.SCM_CREDENTIALS)) {
                                sshagent([env.SCM_CREDENTIALS]) {
                                    sh("ls -l ${script} && chmod +x ${script} && ${script}")
                                }
                            } else {
                                sh("ls -l ${script} && chmod +x ${script} && ${script}")
                            }
                    }
                    /*
                    }*/
                }
            }
        }
    }
}

void sequential(app_envs) {
    if (env.VERBOSE > 1) {
        println "process.sequential(${app_envs})"
    }    

    node() {
        for (app_env in app_envs) {
            if (app_env != null) {
                stage("${app_env}") {
                    process app_env
                }
            }
        }
    }
}

void parallel(app_envs) {
    if (env.VERBOSE > 1) {
        println "process.parallel(${app_envs})"
    }    

    // See also Parallel From List, https://www.jenkins.io/doc/pipeline/examples/#parallel-multiple-nodes
    
    // While you can't use Groovy's .collect or similar methods currently, you can
    // still transform a list into a set of actual build steps to be executed in
    // parallel.

    // The map we'll store the parallel steps in before executing them.
    Map parallel_steps = app_envs.collectEntries {
        it != null ? ["${it}" : transform_to_step(it)] : [:]
    }
    
    // Actually run the steps in parallel - parallel takes a map as an argument,
    // hence the above.

    // PLEASE BE CAREFUL: parallel is also a Jenkins pipeline step so add steps. in front
    steps.parallel parallel_steps
}

// Take the string and echo it.
void transform_to_step(app_env) {
    // We need to wrap what we return in a Groovy closure, or else it's invoked
    // when this method is called, not when we pass it to parallel.
    // To do this, you need to wrap the code below in { }, and either return
    // that explicitly, or use { -> } syntax.
    return {
        node {
            process app_env
        }
    }
}

String get_env(app_env_name, app_env, String key, Boolean mandatory=true, Integer level=3, String default_value='') {
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
                error = "Either application environment variable 'pipelineConfig.application_environments.${app_env_name}.${key}' or " +
                    "pipeline configuration variable 'pipelineConfig.${key}' or " +
                    "environment variable '${KEY}' must be a non-empty string"
                break
            case 2:
                error = "Either application environment variable 'pipelineConfig.application_environments.${app_env_name}.${key}' or " +
                    "pipeline configuration variable 'pipelineConfig.${key}' must be a non-empty string"
                break
            case 1:
                error = "Application environment variable 'pipelineConfig.application_environments.${app_env_name}.${key}' must be a non-empty string"
                break
            default:
                assert level >= 1 && level <= 3: "Level must be between 1 and 3"
        }
        
        assert !is_empty(value) : error
    }

    if (env.VERBOSE > 0) {
        println "Setting environment variable $KEY to '$value'"
    }
    
    return value
}

void show_env(app_env, pipelineConfig, env) {
    if (!(env.VERBOSE > 0)) {
        return
    }

    String[] properties = [ 'apex_actions'
                           ,'apex_dir'
                           ,'conf_dir'
                           ,'db'
                           ,'db_actions'
                           ,'db_credentials'
                           ,'db_dir'
                           ,'dry_run'
                           ,'mvn'
                           ,'mvn_args'
                           ,'mvn_log_dir'
                           ,'scm_branch'
                           ,'scm_branch_config'
                           ,'scm_branch_oracle_tools'
                           ,'scm_branch_prev'
                           ,'scm_credentials'
                           ,'scm_credentials_config'
                           ,'scm_email'
                           ,'scm_project'
                           ,'scm_project_config'
                           ,'scm_project_oracle_tools'
                           ,'scm_url'
                           ,'scm_url_config'
                           ,'scm_url_oracle_tools'
                           ,'scm_username'
    ]

    println "Start of showing the application environment, pipeline configuration and environment"
    
    for (String property in properties.sort()) {
        String v = app_env.getProperty(property)
        
        if (!is_empty(v)) {
            println "app_env.$property = " + v
        }
    }
    pipelineConfig.sort().each{k, v -> if (properties.contains(k) && !is_empty(v)) { println "pipelineConfig.$k = $v" }}
    env.getEnvironment().sort().each{k, v -> if (properties.contains(k.toLowerCase()) && !is_empty(v)) { println "env.$k = $v" }}

    println "End of showing the application environment, pipeline configuration and environment"
}

Boolean is_empty(value) {
    return value == null || value.toString().equals("") || value.toString().equals("[]") || value.toString().equals("{[:]")
}
