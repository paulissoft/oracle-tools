// accessible via JTEs pipelineConfig
maven = 'maven-3'
scm_branch_oracle_tools = 'development'
// a clone without credentials
scm_url_oracle_tools = 'http://github.com/paulissoft/oracle-tools.git'

libraries{
//  merge = true 
  maven
}

application_environments{
    dev{
        // Oracle tools info
        scm_branch = 'development'
        scm_credentials = 'paulissoft'
        scm_url = 'git@github.com:paulissoft/oracle-tools.git'
        scm_username = 'paulissoft'
        scm_email = 'paulissoft@gmail.com'

        conf_dir = 'conf/src'

        db = 'docker'
        db_host = 'host.docker.internal'
        db_credentials = 'oracle-tools-development'
        db_dir = 'db/app'
        db_actions = 'db-info db-install db-generate-ddl-full'

        apex_dir = 'apex/app'
        apex_actions = 'apex-export'
    }
    test{
        // Oracle tools info
        scm_branch = 'test'
        scm_credentials = 'paulissoft'
        scm_url = 'git@github.com:paulissoft/oracle-tools.git'
        scm_username = 'paulissoft'
        scm_email = 'paulissoft@gmail.com'

        conf_dir = 'conf/src'

        db = 'docker'
        db_host = 'host.docker.internal'
        db_credentials = 'oracle-tools-development'
        db_dir = 'db/app'
        db_actions = 'db-info db-install db-generate-ddl-full'

        apex_dir = 'apex/app'
        apex_actions = 'apex-import'
    }
}
