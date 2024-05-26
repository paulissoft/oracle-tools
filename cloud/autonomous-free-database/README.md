# Create an autonomous free database

The creation of an autonomous free database will be executed by Terraform using the articles found on https://oracle-base.com.

Instructions are based on [Terraform : Linking Oracle Cloud Interface (OCI) Terraform Modules Together](https://oracle-base.com/articles/misc/terraform-linking-oci-modules-together).

However since the Oracle Cloud UI has changed since the creation of those instructions, I will update the instructions where applicable.

All code Terraform files (`*.tf`) mentioned in those articles are stored in this folder: `oracle-tools/cloud/autonomous-free-database`.

The variable Terraform files (`*.auto.tfvars`) should **NOT** be stored in a Git repository. The file `oracle-tools/.gitignore` does already exclude them.


## [Terraform : Oracle Cloud Infrastructure (OCI) Provider](https://oracle-base.com/articles/misc/terraform-oci-provider)

### Add Public Key to Oracle Cloud Account

There is a section named "Add Public Key to Oracle Cloud Account" that is not correct anymore: the "Add API Key" button can now be found as follows:
- Profile > My Profile > API keys
- Click "Add API key" button, toggle "Paste a public key" and paste the public key including "-----BEGIN PUBLIC KEY-----" and "-----END PUBLIC KEY-----"

### User OCID

To get the user OCID:
- Profile > My Profile > User information -> OCID
- Click the "Copy" link next to "OCID".

## [Terraform : Oracle Cloud Infrastructure (OCI) Compartment](https://oracle-base.com/articles/misc/terraform-oci-compartment)

