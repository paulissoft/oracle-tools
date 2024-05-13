---
layout: default
title: Architecture
nav_order: 3
---

# Architecture
{: .no_toc }

Here I will explain what the architecture is and why I have chosen it.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}


## What I need?

Well, what I essentially need is a framework that lets me build (Oracle)
database applications quickly (but not dirty).

And as far as I know there is just one product that excels in installing database
applications using migration scripts: [Flyway](www.flywaydb.org).

Besides that, you also need to be able to install the client, for instance Oracle APEX.

Or other tools you may need to invoke.

So, instead of remembering all the tools and its parameters or configuration, I
just like to use just one command line tool. In the good old days of C
programming, the make utility might have been a good candidate but nowadays I
think the best candidate is Maven.

## What is Maven?

From [Welcome to Apache Maven](https://maven.apache.org/index.html):

> Apache Maven is a software project management and comprehension tool. Based on
> the concept of a project object model (POM), Maven can manage a project's
> build, reporting and documentation from a central piece of information.

## So why Maven?

Maven is usually used in Java projects but it is not just limited to that.

Maven can:
- download programs, plugins and libraries (using its Maven repository)
- invoke Ant to set up properties thru property files (something that Maven can not)
- invoke Flyway
- compile and run Java
- invoke SQLcl (the Java successor of SQL*Plus) to import/export APEX

See also the [Maven Getting Started Guide](https://maven.apache.org/guides/getting-started/index.html).

So, actually Maven can do all I need. But there are some problems with Maven.

## Maven pitfalls

### No procedural language

Maven has the concept of a build life cycle which comes in handy when you must
compile a Java program or (web) library, test and deploy it. But I just
need to be able to perform some tasks that may not be related at all. If I install
APEX I do not necessarily need to install into the (same) database nor test it. Or I
may need to work on two different databases, and so on.

I just need to perform a limited number of actions and for each action I may
need to have a different configuration.

The closest thing to my action in Maven is a [Build
Profile](https://maven.apache.org/guides/introduction/introduction-to-profiles.html).

You can get a list of all profiles by:

```
$ mvn help:all-profiles -N
```

### Maven release numbering

In a blog about [Maven Release Plugin: Dead and
Buried](https://axelfontaine.com/blog/dead-burried.html), Axel Fontaine
describes the problems there are with creating Maven releases by increasing
the POM version property. This has always been a weak point in Maven but since
Maven 3.3.1 introducing the maven.multiModuleProjectDirectory property set by
a file called .mvn/maven.config, most of the problems have disappeared. You
can define the root of project using ${maven.multiModuleProjectDirectory} and
you can use ${revision} for your (parent) pom version. There is no need
anymore to use constant version numbers, **provided** you do not use POM
artifacts neither.

So my approach is to:
- checkout PATO (to directory dev for instance)
- checkout any project that uses PATO on the same level (also to dev)

Now another project POM in <project>/db, can have as parent one of the PATO POMs like this:

```
<parent>
  <groupId>com.paulissoft.pato</groupId>
  <artifactId>db</artifactId>
  <version>${revision}</version>
  <relativePath>../../oracle-tools/db</relativePath>
</parent>
```

### Maven configuration

Another problem for Maven is that the properties are determined by (in order):
1. a command line option (-Dproperty=value)
2. a user settings file ($HOME/.m2/settings.xml by default)
3. a POM (child POMs having more priority)

But this is quite static. What I would like is that some properties can be
read from property files just like Ant does.

So my solution is to read those property files using the [Maven AntRun Plugin](https://maven.apache.org/plugins/maven-antrun-plugin/) and
export them into the Maven namespace.

This allows me to define a configuration directory containing property files
and within that directory you may have subdirectories each representing a
database with its properties you would like to store (not passwords of
course). And that can be APEX properties as well like workspace or application
id. Please note that APEX is part of a database so it is the obvious place to
store the configuration there.

The database password is by the default the value of the environment variable
DB_ENVIRONMENT, a best practice described in [The Twelve-Factor
App](https://12factor.net/) since it allows you to **not** set it on the
command line.
