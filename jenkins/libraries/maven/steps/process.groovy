// -*- mode: groovy; coding: utf-8 -*-
import org.boozallen.plugins.jte.init.primitives.injectors.ApplicationEnvironment

void call(List app_envs, Boolean parallel_step=false, Boolean clean_workspace=false) {
    if (verbose > 1) {
        println "process(app_envs: ${app_envs}, parallel_step: ${parallel_step}, clean_workspace: ${clean_workspace})"
    }    

    if (clean_workspace) {
        cleanWs()
    }
    
    if (parallel_step) {
        // See also Parallel From List, https://www.jenkins.io/doc/pipeline/examples/#parallel-multiple-nodes
    
        // While you can't use Groovy's .collect or similar methods currently, you can
        // still transform a list into a set of actual build steps to be executed in
        // parallel.

        // The map we'll store the parallel steps in before executing them.
        Map parallel_steps = app_envs.collectEntries {
            it instanceof ApplicationEnvironment ? ["${it}" : transform_to_step(it)] : [:]
        }
    
        // Actually run the steps in parallel - parallel takes a map as an argument,
        // hence the above.

        // PLEASE BE CAREFUL: parallel is also a Jenkins pipeline step so add steps. in front
        steps.parallel parallel_steps
    } else {
        node() {
            for (app_env in app_envs) {
                if (app_env instanceof ApplicationEnvironment) {
                    stage("${app_env}") {
                        process app_env
                    }
                }
            }
        }
    }
}

void call(ApplicationEnvironment app_env, Boolean parallel_step=false) {
    String app_env_name = app_env.name
    Map vars = [:] // new environment variables
        
    if (verbose > 1) {
        println "process(app_env: ${app_env}, parallel_step: ${parallel_step})"
    }    

    script {        
        stage("${app_env_name} - setup environment") {
            show_env(app_env, pipelineConfig, env)
                        
            assert !"${env.WORKSPACE}".contains(" "): "Workspace (${env.WORKSPACE}) should not contain spaces"
            
            /*
             -- The SCM PATO project needed to build the SCM project
             */

            vars.SCM_URL_ORACLE_TOOLS = get_env(app_env_name, app_env, 'scm_url_oracle_tools', false)
            vars.SCM_BRANCH_ORACLE_TOOLS = get_env(app_env_name, app_env, 'scm_branch_oracle_tools', !is_empty(vars.SCM_URL_ORACLE_TOOLS)) // mandatory if the URL is there
            if (!is_empty(vars.SCM_URL_ORACLE_TOOLS)) {
                String name = vars.SCM_URL_ORACLE_TOOLS.substring(vars.SCM_URL_ORACLE_TOOLS.lastIndexOf("/") + 1).replaceAll("\\.git\$", "")
                
                vars.SCM_PROJECT_ORACLE_TOOLS = get_env(app_env_name, app_env, 'scm_project_oracle_tools', true, 3, name).replaceAll(" ", "_")
            }
            
            /*
             -- The SCM (database) configuration project needed to build the SCM project
             */

            vars.SCM_URL_CONFIG = get_env(app_env_name, app_env, 'scm_url_config', false)
            vars.SCM_BRANCH_CONFIG = get_env(app_env_name, app_env, 'scm_branch_config', !is_empty(vars.SCM_URL_CONFIG)) // mandatory if the URL is there
            vars.SCM_CREDENTIALS_CONFIG = get_env(app_env_name, app_env, 'scm_credentials_config', false)
            if (!is_empty(vars.SCM_URL_CONFIG)) {
                String name = vars.SCM_URL_CONFIG.substring(vars.SCM_URL_CONFIG.lastIndexOf("/") + 1).replaceAll("\\.git\$", "")
                
                vars.SCM_PROJECT_CONFIG = get_env(app_env_name, app_env, 'scm_project_config', true, 3, name).replaceAll(" ", "_")
            }
            
            /*
             -- The configuration directory to work on
             */
            
            vars.CONF_DIR = get_env(app_env_name, app_env, 'conf_dir')

            /*
             -- The database info to work on
             */
            
            vars.DB = get_env(app_env_name, app_env, 'db', true, 1)
            vars.DB_CREDENTIALS = get_env(app_env_name, app_env, 'db_credentials', true, 1) // application environment specific
            vars.DB_DIR = get_env(app_env_name, app_env, 'db_dir')
            vars.DB_ACTIONS = get_env(app_env_name, app_env, 'db_actions', false, 2) // application environment or pipeline configuration specific

            /*
             -- The APEX info to work on
             */
            
            vars.APEX_DIR = get_env(app_env_name, app_env, 'apex_dir')
            vars.APEX_ACTIONS = get_env(app_env_name, app_env, 'apex_actions', false, 2) // application environment or pipeline configuration specific

            /*
             -- SCM credentials username and e-mail
             */
            
            // It must be possible to specify the SCM username and email as environment variables in Jenkins configuration.
            // https://github.com/paulissoft/oracle-tools/issues/70
            Boolean credentials_needed = (vars.DB_ACTIONS =~ /\bdb-generate-ddl-full\b/) || (vars.APEX_ACTIONS =~ /\bapex-export\b/)
            
            vars.SCM_USERNAME = get_env(app_env_name, app_env, 'scm_username', credentials_needed)
            vars.SCM_EMAIL = get_env(app_env_name, app_env, 'scm_email', credentials_needed)

            /*
             -- The SCM project to work on
             */
            
            vars.SCM_BRANCH = get_env(app_env_name, app_env, 'scm_branch', true, 1)
            vars.SCM_BRANCH_PREV = get_env(app_env_name, app_env, 'scm_branch_prev', false, 1, ( app_env.previous != null ? app_env.previous.scm_branch : '' ))
            vars.SCM_CREDENTIALS = get_env(app_env_name, app_env, 'scm_credentials', credentials_needed)
            vars.SCM_URL = get_env(app_env_name, app_env, 'scm_url', true)
            vars.SCM_PROJECT = get_env(app_env_name, app_env, 'scm_project', true, 3, vars.SCM_URL.substring(vars.SCM_URL.lastIndexOf("/") + 1).replaceAll("\\.git\$", "")).replaceAll(" ", "_")

            // It must be possible to have a dry run for Jenkins.
            // https://github.com/paulissoft/oracle-tools/issues/84
            vars.DRY_RUN = get_env(app_env_name, app_env, 'dry_run', false)
            // It must be possible to use the Maven daemon in Jenkins.
            // https://github.com/paulissoft/oracle-tools/issues/82
            vars.MVN = get_env(app_env_name, app_env, 'mvn', true, 3, 'mvn')
            vars.MVN_ARGS = get_env(app_env_name, app_env, 'mvn_args', false)
            vars.MVN_LOG_DIR = get_env(app_env_name, app_env, 'mvn_log_dir', false)

            if (parallel_step) {
                vars.APP_ENV = app_env.name
                if (app_env.previous != null) {
                    vars.APP_ENV_PREV = app_env.previous.name
                }
            }
        }
    }
    
    withCredentials([usernamePassword(credentialsId: vars.DB_CREDENTIALS, passwordVariable: 'DB_PASSWORD', usernameVariable: 'DB_USERNAME')]) {
        // checkout of (optional) configuration project (maybe credentials needed)
        script {
            // skip checkout if the configuration project is the same as project            
            if (!is_empty(vars.SCM_PROJECT_CONFIG) &&
                !vars.SCM_PROJECT_CONFIG.equals(vars.SCM_PROJECT)) {
                stage("${app_env_name} - checkout configuration project") {
                    echo "About to check-out configuration project, " +
                        "url='${vars.SCM_URL_CONFIG}', " +
                        "branch='${vars.SCM_BRANCH_CONFIG}', " +
                        "directory='${app_env_name}/${vars.SCM_PROJECT_CONFIG}', " +
                        "credentials='${vars.SCM_CREDENTIALS_CONFIG}'"
                    dir("${app_env_name}/${vars.SCM_PROJECT_CONFIG}") {
                        if (vars.DRY_RUN) {
                            echo "Skipping check-out since it is a dry run"
                        } else if (!is_empty(vars.SCM_CREDENTIALS_CONFIG)) {
                            git url: vars.SCM_URL_CONFIG, branch: vars.SCM_BRANCH_CONFIG, credentialsId: vars.SCM_CREDENTIALS_CONFIG
                        } else {
                            checkout([
                                $class: 'GitSCM', 
                                branches: [[name: '*/' + vars.SCM_BRANCH_CONFIG]], 
                                doGenerateSubmoduleConfigurations: false, 
                                extensions: [[$class: 'CleanCheckout']], 
                                submoduleCfg: [], 
                                userRemoteConfigs: [[url: vars.SCM_URL_CONFIG]]
                            ])
                        }
                    }
                }
            }
        }
        
        // checkout of (optional) PATO (no credentials needed)
        script {
            // skip checkout if the PATO project is the same as the (configuration) project
            if (!is_empty(vars.SCM_PROJECT_ORACLE_TOOLS) &&
                (is_empty(vars.SCM_PROJECT)        || !vars.SCM_PROJECT_ORACLE_TOOLS.equals(vars.SCM_PROJECT)) &&
                (is_empty(vars.SCM_PROJECT_CONFIG) || !vars.SCM_PROJECT_ORACLE_TOOLS.equals(vars.SCM_PROJECT_CONFIG))) {
                stage("${app_env_name} - checkout PATO project") {
                    echo "About to check-out PATO project, " +
                        "url='${vars.SCM_URL_ORACLE_TOOLS}', " +
                        "branch='${vars.SCM_BRANCH_ORACLE_TOOLS}', " +
                        "directory='${app_env_name}/${vars.SCM_PROJECT_ORACLE_TOOLS}', " +
                        "no credentials"
                    dir("${app_env_name}/${vars.SCM_PROJECT_ORACLE_TOOLS}") {
                        if (vars.DRY_RUN) {
                            echo "Skipping check-out since it is a dry run"
                        } else {
                            checkout([
                                $class: 'GitSCM', 
                                branches: [[name: '*/' + vars.SCM_BRANCH_ORACLE_TOOLS]], 
                                doGenerateSubmoduleConfigurations: false, 
                                extensions: [[$class: 'CleanCheckout']], 
                                submoduleCfg: [], 
                                userRemoteConfigs: [[url: vars.SCM_URL_ORACLE_TOOLS]]
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
                    "url='${vars.SCM_URL}', " +
                    "branch='${vars.SCM_BRANCH}', " +
                    "directory='${app_env_name}/${vars.SCM_PROJECT}', " +
                    "credentials='${vars.SCM_CREDENTIALS}'"
                dir("${app_env_name}/${vars.SCM_PROJECT}") {
                    if (vars.DRY_RUN) {
                        echo "Skipping check-out since it is a dry run"
                    } else if (!is_empty(vars.SCM_CREDENTIALS)) {                    
                        git url: vars.SCM_URL, branch: vars.SCM_BRANCH, credentialsId: vars.SCM_CREDENTIALS
                    } else {
                        checkout([
                            $class: 'GitSCM', 
                            branches: [[name: '*/' + vars.SCM_BRANCH]], 
                            doGenerateSubmoduleConfigurations: false, 
                            extensions: [[$class: 'CleanCheckout']], 
                            submoduleCfg: [], 
                            userRemoteConfigs: [[url: vars.SCM_URL]]
                        ])
                    }
                    
                    echo "About to execute Maven actions"

                    String oracle_tools = vars.SCM_PROJECT_ORACLE_TOOLS ?: ${vars.SCM_PROJECT}
                    String process_script = "$WORKSPACE/${app_env_name}/${oracle_tools}/jenkins/process.sh"
                    String script = "set +xv\n" +
                        vars.collect({key, value -> /export $key='$value'/}).join("\n") +
                        """
set -xv
ls -l ${process_script}
chmod +x ${process_script}
env
${process_script}
"""

                    if (verbose > 0) {
                        echo "Script to execute:\n${script}"
                    }

                    if (vars.DRY_RUN) {
                        echo "Skipping the execution of Maven actions since it is a dry run"
                    } else {
                        if (!is_empty(vars.SCM_CREDENTIALS)) {
                            sshagent([vars.SCM_CREDENTIALS]) {
                                sh(script)
                            }
                        } else {
                            sh(script)
                        }
                    }
                }
            }
        }
    }
}

// Take the string and echo it.
void transform_to_step(app_env) {
    // We need to wrap what we return in a Groovy closure, or else it's invoked
    // when this method is called, not when we pass it to parallel.
    // To do this, you need to wrap the code below in { }, and either return
    // that explicitly, or use { -> } syntax.
    return {
        node {
            process app_env, true
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

    if (verbose > 0) {
        println "Setting environment variable $KEY to '$value'"
    }
    
    return value
}

void show_env(app_env, pipelineConfig, env) {
    if (!(verbose > 0)) {
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

Integer verbose() {
    String VERBOSE = env.VERBOSE ?: ""
    return VERBOSE.isInteger() ? VERBOSE as Integer : 0
}
