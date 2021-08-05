# k8s-baremetal-aws

Creation of a fully fonctionnal K8S baremetal cluster with 3 nodes and 1 master.

This project uses :
* Terraform
* AWS

To use it :
* configure AWS with a profil
* update file variable.tf with the right profile / region / ami (debian)-
* terraform init
* terraform apply
* terraform output

Then hit the "master_dns" to get to the dashboard

