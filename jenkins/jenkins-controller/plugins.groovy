Jenkins.instance.pluginManager.plugins.each{
    plugin ->
    println ("${plugin.getShortName()}")
    // println ("${plugin.getDisplayName()} (${plugin.getShortName()}): ${plugin.getVersion()}")
}
