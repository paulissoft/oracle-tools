# ADMIN

The ADB processing should not process these objects:
- PACKAGE `ADMIN_INSTALL_PKG`
- VIEW `GITHUB_INSTALLED_VERSIONS_V`
- TABLE `GITHUB_INSTALLED_PROJECTS`
- TABLE `GITHUB_INSTALLED_VERSIONS`
- TABLE `GITHUB_INSTALLED_VERSIONS_OBJECTS`

This is accomplished by excluding them in package body `ADMIN_INSTALL_PKG` in function `do_not_install_file`.
