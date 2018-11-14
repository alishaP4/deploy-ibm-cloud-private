################################################################
# Module to deploy IBM Cloud Private
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# Copyright IBM Corp. 2017.
#
################################################################

variable "openstack_user_name" {
    description = "The user name used to connect to OpenStack"
    default = "my_user_name"
}

variable "openstack_password" {
    description = "The password for the user"
    default = "my_password"
}

variable "openstack_project_name" {
    description = "The name of the project (a.k.a. tenant) used"
    default = "ibm-default"
}

variable "openstack_domain_name" {
    description = "The domain to be used"
    default = "Default"
}

variable "openstack_auth_url" {
    description = "The endpoint URL used to connect to OpenStack"
    default = "https://<HOSTNAME>:5000/v3/"
}

variable "openstack_image_id" {
    description = "The ID of the image to be used for deploy operations"
    default = "my_image_id"
}

variable "openstack_flavor_id_master_node" {
    description = "The ID of the flavor to be used for ICP master node deploy operations"
    default = "my_flavor_id"
}

variable "openstack_flavor_id_worker_node" {
    description = "The ID of the flavor to be used for ICP worker node deploy operations"
    default = "my_flavor_id"
}

variable "openstack_network_name" {
    description = "The name of the network to be used for deploy operations"
    default = "my_network_name"
}

variable "openstack_ssh_key_file" {
    description = "The path to the private SSH key file. Appending '.pub' indicates the public key filename"
    default = "<path to the private SSH key file>"
}

variable "icp_install_user" {
    description = "The user with sudo access across nodes (users section of cloud-init)"
    default = "ubuntu"
}

variable "icp_install_user_password" {
   description = "Password for sudo access (leave empty if using passwordless sudo access)"
   default = ""
}

variable "icp_num_workers" {
    description = "The number of ICP worker nodes to provision"
    default = 1
}
#..................................................addition.......................................................

variable "openstack_availability_zone" {
    description = "The availability zone"
    default = "PowerKVM"
}

variable "openstack_security_groups" {
  type    = "list"
  default = ["default"]
}

variable "if_HA" {
    description = "If HA configurations are required then mark it as true"
    default = false
}

variable "cluster_vip" {
  description = "Virtual IP for Master Console"
  default     = "127.0.1.1"
}

variable "proxy_vip" {
  description = "Virtual IP for Master Console" #proxy console
  default     = "127.0.1.1"
}

variable "icp_num_masters" {
    description = "The number of ICP master nodes to provision"
    default = 1
}

variable instances {
   type = "map"   
   
   default   {     
   backend = "2"   
   } 
 }

variable "icp_num_proxy" {
    description = "The number of ICP proxy nodes to provision"
    default = 1
}

variable "icp_num_management" {
    description = "The number of ICP management nodes to provision"
    default = 1
}

variable "registry_mount_src" {
  description = "Mount point containing the shared registry directory for /var/lib/registry"
  default     = ""
}

variable "reg_path" {
  description = "//reg_path: 9.37.39.xxx:/var/nfs/icp/registry, "
  default     = ""
}

variable "registry_mount_type" {
  description = "Mount Type of registry shared storage filesystem"
  default     = "nfs"
}

variable "registry_mount_options" {
  description = "Additional mount options for registry shared directory"
  default     = "defaults"
}

variable "audit_mount_src" {
  description = "Mount point containing the shared registry directory for /var/lib/icp/audit"
  default     = ""
}

variable "auth_audit_path" {
  description = "//auth_audit_path: 9.37.39.xxx:/var/nfs/icp/authaudit"
  default     = ""
}

variable "audit_mount_type" {
  description = "Mount Type of registry shared storage filesystem"
  default     = "nfs"
}

variable "audit_mount_options" {
  description = "Additional mount options for audit shared directory"
  default     = "defaults"
}

variable "kub_audit_mount_src" {
  description = "Mount point containing the shared registry directory for /var/log/audit"
  default     = ""
}

variable "kub_audit_path" {
  description = "//kub_audit_path: 9.37.39.xxx:/var/nfs/icp/kubaudit"
  default     = ""
}

variable "kub_audit_mount_type" {
  description = "Mount Type of registry shared storage filesystem"
  default     = "nfs"
}

variable "kub_audit_mount_options" {
  description = "Additional mount options for registry shared directory"
  default     = "defaults"
}
#................................................................XXXXXX..................................................

variable "icp_edition" {
    description = "ICP edition - either 'ee' for Enterprise Edition or 'ce' for Community Edition"
    default = "ce"
}

variable "icp_version" {
    description = "ICP version number"
    default = "2.1.0.3"
}

variable "icp_architecture" {
    description = "x86 or ppc64le"
    default = "ppc64le"
}

variable "icp_download_location" {
    description = "HTTP wget location for ICP Enterprise Edition - ignored for community edition"
    default = "http://LOCATION_OF_ICP_ENTERPRISE_EDITION.tar.gz"
}

variable "icp_disabled_services" {
    type = "list"
    description = "List of ICP services to disable (e.g., va, monitoring or metering)"
    default = [
	"va"
    ]
}

variable "instance_prefix" {
    description = "Prefix to use in instance names"
    default = "icp"
}

variable "docker_download_location" {
    description = "HTTP wget location for ICP provided Docker package"
    default = ""
}
