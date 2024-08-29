# Create an autonomous free database & OCI compute instance

The creation of an autonomous free database & OCI compute instance will be executed by Terraform using the articles found on https://oracle-base.com.

**Important**: you have to create the autonomous free database **before** creating the OCI compute instance since the datbase VCN public subnet will be used during the OCI compute instance creation.

Instructions are based on [Terraform : Linking Oracle Cloud Interface (OCI) Terraform Modules Together](https://oracle-base.com/articles/misc/terraform-linking-oci-modules-together).

However since the Oracle Cloud UI has changed since the creation of those instructions, I will update the instructions where applicable.

All code Terraform files (`*.tf`) mentioned in those articles need not be (re-)created since they are already stored in this folder: `oracle-tools/cloud/terraform`.

However, the variable Terraform files (`*.auto.tfvars`) must be created and should **NOT** be stored in a Git repository. The file `oracle-tools/.gitignore` does already exclude them.

## [Terraform : Oracle Cloud Infrastructure (OCI) Provider](https://oracle-base.com/articles/misc/terraform-oci-provider)

### Add Public Key to Oracle Cloud Account

There is a section named "Add Public Key to Oracle Cloud Account" that is not correct anymore: the "Add API Key" button can now be found as follows:
- Profile > My Profile > API keys
- Click "Add API key" button, toggle "Paste a public key" and paste the public key (including "-----BEGIN PUBLIC KEY-----" and "-----END PUBLIC KEY-----")

### User OCID

To get the user OCID:
- Profile > My Profile > User information -> OCID
- Click the "Copy" link next to "OCID".

## [Terraform : Oracle Cloud Infrastructure (OCI) Compartment](https://oracle-base.com/articles/misc/terraform-oci-compartment)

No changes.

## [Terraform : Oracle Cloud Infrastructure (OCI) Virtual Cloud Network (VCN)](https://oracle-base.com/articles/misc/terraform-oci-vcn)

No changes.

## [Terraform : Oracle Cloud Infrastructure (OCI) Autonomous Database (ADW, ATP, AJD, APX)](https://oracle-base.com/articles/misc/terraform-oci-autonomous-database)

No changes.

## [Terraform : Oracle Cloud Infrastructure (OCI) Compute Instance](https://oracle-base.com/articles/misc/terraform-oci-compute-instance)

The variables "compartment_id" and "compute_shape" have been removed from the file `oci_compute_variables.auto.tfvars` since other values will be used in `oci_compute.tf`.

For variable "compute_subnet_id" I used the OCID of the public subnet of the autonomous database VCN.
For variable "compute_image_id" I used the OCID for OS image Oracle-Linux-9.4-2024.07.31-0 in region eu-frankfurt-1.

For variable "compute_ssh_authorized_keys" I used the full name of my RSA public key file in the `$HOME/.ssh` directory.

## [Terraform : Linking Oracle Cloud Interface (OCI) Terraform Modules Together](https://oracle-base.com/articles/misc/terraform-linking-oci-modules-together)

Now continue with the rest of this article; the amendments have already been made.

As soon as you have created the database, it will take some time before the new compartment shows up in the compartment list scope due to synchronization matters. Only when you see the new compartment arrive there, you will be able to see the PATO database you just created.

## Post actions

### Terraform and `.gitignore`

See https://github.com/github/gitignore/blob/main/Terraform.gitignore for an example of files/folders to ignore.

### Using Object Storage for Terraform State Files

We are going to set up Terraform remote state using the Oracle cloud bucket storage which is compatible with AWS S3.

See also [Using Object Storage for State Files](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformUsingObjectStore.htm).

#### Create a custom secret key

See the link above.

#### Create a bucket

I suggest to create one bucket for all Terraform states and let the key be Terraform project specific.

So, here the bucket will be "terraform-states" and the key "autonomous-free-database/terraform/terraform.tfstate".

Create a file named `backend.tf` and add it to `.gitignore` since it contains secrets.

```backend.tf
terraform {
  backend "s3" {
    bucket   = "terraform-states"
    key      = "autonomous-free-database/terraform/terraform.tfstate"
    region   = "<region>"
    endpoints = { s3 = "https://<namespace>.compat.objectstorage.<region>.oraclecloud.com" }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
```

Replace `<region>` and `<namespace>`.

Issue the following command to upload the state into the bucket:

```
$ terraform init
```

## Conclusion

Using resources from various sites we have been able to create a free and autonomous database, whose creation is fully automated by Terraform and manageable from various computers thanks to the remote storage used for Terraform state. The variable files and the remote state storage backend file must **NOT** be part of Git for security reasons.
