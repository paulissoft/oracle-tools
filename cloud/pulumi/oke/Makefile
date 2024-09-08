TENANCY_OCID := $(shell grep -E '^tenancy=' $(HOME)/.oci/config | cut -d '=' -f 2)
USER_OCID := $(shell grep -E '^user=' $(HOME)/.oci/config | cut -d '=' -f 2)
FINGERPRINT := $(shell grep -E '^fingerprint=' $(HOME)/.oci/config | cut -d '=' -f 2)
REGION := $(shell grep -E '^region=' $(HOME)/.oci/config | cut -d '=' -f 2)

# From https://docs.oracle.com/en/learn/oci-oke-pulumi/index.html#create-a-new-python-stack

login:
	pulumi login

init:
	pulumi new python --force
	pulumi up

install:
	. venv/bin/activate && pip install pulumi_oci

config:
	echo "Checking whether ~/.oci/config file exists" && test -f ~/.oci/config
	pulumi config set oci:tenancyOcid '$(TENANCY_OCID)' --secret  
	pulumi config set oci:userOcid '$(USER_OCID)' --secret
	pulumi config set oci:fingerprint '$(FINGERPRINT)' --secret
	pulumi config set oci:region '$(REGION)'
	cat $$HOME/.oci/*key.pem | pulumi config set oci:privateKey --secret
	pulumi config set compartment_ocid

show-config:
	pulumi config
