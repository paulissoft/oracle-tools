# OCI client interface

Based on the following links:
- [Create and use an Oracle Autonomous Cloud Database from the Command Line](https://learncodeshare.net/2020/04/06/create-and-use-an-oracle-autonomous-cloud-database-from-the-command-line/)
- [Install and Configure the Oracle Cloud Command Line Interface](https://learncodeshare.net/2020/03/06/install-and-configure-the-oracle-cloud-command-line-interface/)
- [Completely cleaning up the contents of an OCI compartment](https://www.ateam-oracle.com/post/cleanup-an-oci-compartment)
- [ociextirpater](https://github.com/therealcmj/ociextirpater)

The scripts in this directory allow you to automatically:
- download the wallet for connecting to an autonomous database
- connect to an autonomous database and issue a simple query as a king of ping

But first we need to install and configure the Oracle Cloud Infrastructure CLient Interface (OCI CLI).

## Install and configure OCI

### Install

I like to use [Miniconda](https://docs.anaconda.com/free/miniconda/index.html) for my Python environments. So install it and create an environment `oci`, activate it and install the OCI client interface:

```
conda create -n oci python 
conda activate oci
pip install oci-cli
```

Test it by:

```
oci -v
```

In the future you will need to activate the environment `oci` for every session where you run one of the scripts below.

### Configure

See the instructions in [the Terraform README](../terraform/README.md) for creating a RSA key pair and putting it in `$HOME/.oci`.

See also those instructions for all the information you need from the Oracle Cloud. You will find them in file `../terraform/oci_provider_variables.auto.tfvars` if you followed those instructions.

Run the setup:

```
oci setup config
```

Test it:

```
oci iam availability-domain list
```

## Download the wallet

Inspired by [Create and use an Oracle Autonomous Cloud Database from the Command Line](https://learncodeshare.net/2020/04/06/create-and-use-an-oracle-autonomous-cloud-database-from-the-command-line/).

Run script `download_wallet.sh`.

## Connect to the database

Inspired on [SHELL SCRIPT TO KEEP ORACLE ALWAYS FREE AUTONOMOUS DATABASE ALIVE WITH SQLCL](https://easyoradba.com/2021/03/10/shell-script-to-keep-oracle-always-free-autonomous-database-alive-with-sqlcl/).

Run script `connect_adb.sh`. It will read the admin password from file `../terraform/oci_adb_variables.auto.tfvars` that has been created while setting up the database with Terraform.
