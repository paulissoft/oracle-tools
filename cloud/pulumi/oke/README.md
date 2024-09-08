https://blog.zwindler.fr/2023/04/24/cluster-kubernetes-gratuit-part1/

https://arnoldgalovics.com/free-kubernetes-oracle-cloud/

https://arnoldgalovics.com/oracle-cloud-kubernetes-terraform/

https://faun.pub/free-ha-multi-architecture-kubernetes-cluster-from-oracle-c66b8ce7cc37


## Build a Container Engine for Kubernetes (OKE) cluster with OCI provider for Pulumi

https://docs.oracle.com/en/learn/oci-oke-pulumi/index.html#task-2-configure-the-python-virtual-environment


However, at one point you need to enter VCN details of the VCN you created yourself.

For more information on the subnet requirements for OKE, such as policy, routing, see the [OCI documentation](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm#example-oci-cni-privatek8sapi_privateworkers_publiclb).

### Create VCN

This will be a manual step: use the VCN wizard and choose the "Create VCN with Internet Connectivity".

I used example 4 from [Example Network Resource Configurations](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm).

#### VCN details

No NAT gateway and no Service Gateway.

#### Subnet details

The wizard only create a public and private subnet and I chose 10.0.2.0/24 for the CIDR Block from the public subnet.

Next step is to add another subnet and rename the subnets:
- private subnet-vcn1 => private-subnet-vcn1-worker-nodes
- public subnet-vcn1 => public-subnet-vcn1-load-balancers
