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
  maven
}

application_environments{
    dev{
        scm_branch = 'development'

        db = 'docker'
        db_credentials = 'oracle-tools-development'
        db_actions = 'db-info db-install db-generate-ddl-full'

        apex_actions = 'apex-export'
    }
    test{
        scm_branch = 'test'

        db = 'docker'
        db_credentials = 'oracle-tools-development'
        db_actions = 'db-info db-install db-generate-ddl-full'

        apex_actions = 'apex-import'
    }
    acc{
        scm_branch = 'acc'

        db = 'docker'
        db_credentials = 'oracle-tools-development'
        db_actions = 'db-info db-install db-generate-ddl-full'

        apex_actions = 'apex-import'
    }
    prod{
        scm_branch = 'prod'

        db = 'docker'
        db_credentials = 'oracle-tools-development'
        db_actions = 'db-info db-install db-generate-ddl-full'

        apex_actions = 'apex-import'
    }
}
