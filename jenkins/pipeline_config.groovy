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
        config_file = 'oracle-tools-config-development'
        maven = 'maven-3'
    }
}

