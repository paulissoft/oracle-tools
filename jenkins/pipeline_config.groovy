/*
  specify which libraries to load: 
    In the Governance Tier configuration file, 
    these should be configurations common across 
    all apps governed by this config. 
*/
libraries{
//  merge = true 
  maven
}

application_environments{
    dev{
        maven = 'maven-3'
        
        // Oracle tools info
        scm_branch=development
        scm_credentials=fd87b3b8-8972-4889-be8d-86342abacb22
        scm_url=git@github.com:paulissoft/oracle-tools.git
        scm_username=paulissoft
        scm_email=paulissoft@gmail.com

        conf_dir=conf/src

        db=docker
        db_host=host.docker.internal
        db_credentials=oracle-tools-development
        db_dir=db/app
        db_actions=db-info db-install db-generate-ddl-full

        apex_dir=apex/app
        // no import or export actions for now since there is no sqlplus nor sql installed on the build agent(s)
        apex_actions=apex-inquiry
    }
}

