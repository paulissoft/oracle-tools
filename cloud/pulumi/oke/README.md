# Setting up an OKE cluster

This README describes how to set up an Oracle Kubernetes Engine (OKE) cluster in the Oracle Cloud.

Several points are important:
1. as automatic as possible - think of Infrastructure as Code (IaC) tools like Terraform or Pulumi (I prefer the latter)
2. low cost - Oracle free tier if possible
3. preferable via Oracle documents or Blogs


So, let's start with: [Build a Container Engine for Kubernetes (OKE) cluster with OCI provider for Pulumi](https://docs.oracle.com/en/learn/oci-oke-pulumi/index.html).

## Build a Container Engine for Kubernetes (OKE) cluster with OCI provider for Pulumi

The beginning is simple but things get complicated in step 5 of [Task 2: Configure the Python virtual environment](https://docs.oracle.com/en/learn/oci-oke-pulumi/index.html#task-2-configure-the-python-virtual-environment).

At that point you have to enter VCN details of the VCN you created yourself: I have none like the one requested.

<blockquote>
For more information on the subnet requirements for OKE, such as policy, routing, see the [OCI documentation](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm#example-oci-cni-privatek8sapi_privateworkers_publiclb).
</blockquote>

So, this is not a trivial task given the Oracle Cloud interface. Can we do better?

Yes, we can (I believe): [Oracle Cloud Infrastructure Designer and Visualisation Toolkit (OKIT)](https://github.com/oracle/oci-designer-toolkit).

### Create VCN

This will be a manual step: use the VCN wizard and choose the "Create VCN with Internet Connectivity".

I used example 4 from [Example Network Resource Configurations](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm).

### Links

- [Un cluster Kubernetes gratuit pour vos labs persos ! - part 1](https://blog.zwindler.fr/2023/04/24/cluster-kubernetes-gratuit-part1/)
- [Running a free Kubernetes cluster on Oracle Cloud](https://arnoldgalovics.com/free-kubernetes-oracle-cloud/)
- [Free Oracle Cloud Kubernetes cluster with Terraform](https://arnoldgalovics.com/oracle-cloud-kubernetes-terraform/)
- [Setup a Free Kubernetes Cluster on Oracle Cloud](https://faun.pub/free-ha-multi-architecture-kubernetes-cluster-from-oracle-c66b8ce7cc37)

- [A weekend project with K3s and Oracle Cloud free tier.](https://medium.com/@Phoenixforge/a-weekend-project-with-k3s-and-oracle-cloud-free-tier-99eda1aa49a0)
