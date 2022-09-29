// accessible via JTEs pipelineConfig

// a clone without credentials
scm_url_oracle_tools = 'http://github.com/paulissoft/oracle-tools.git'
scm_branch_oracle_tools = 'development'

scm_url = 'git@github.com:paulissoft/oracle-tools.git'
scm_credentials = 'github'

conf_dir = 'conf/src'
db_dir = 'db/app'
apex_dir = 'apex/app'

libraries{
//  merge = true 
  maven
}

application_environments{
    dev{
        // Oracle tools info
        scm_branch = 'development'

        db = 'docker'
        db_credentials = 'oracle-tools-development'
        db_actions = 'db-info db-install db-generate-ddl-full'

        apex_actions = 'apex-export'
    }
}
