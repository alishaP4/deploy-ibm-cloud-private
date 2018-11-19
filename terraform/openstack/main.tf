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

provider "openstack" {
    user_name   = "${var.openstack_user_name}"
    password    = "${var.openstack_password}"
    tenant_name = "${var.openstack_project_name}"
    domain_name = "${var.openstack_domain_name}"
    auth_url    = "${var.openstack_auth_url}"
    insecure    = true
}

resource "random_id" "rand" {
    byte_length = 2
}

resource "openstack_compute_keypair_v2" "icp-key-pair" {
    name       = "terraform-icp-key-pair-${random_id.rand.hex}"
    public_key = "${file("${var.openstack_ssh_key_file}.pub")}"
}

resource "openstack_compute_instance_v2" "icp-worker-vm" {
    count     = "${var.icp_num_workers}"
    name      = "${format("${var.instance_prefix}-worker-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_worker_node}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    security_groups = ["${var.openstack_security_groups}"]
    availability_zone = "${var.openstack_availability_zone}"

    network {
        name = "${var.openstack_network_name}"
    }

    user_data = "${data.template_file.bootstrap_worker.rendered}"

    provisioner "local-exec" {
        command = "if ping -c 1 -W 1 $MASTER_IP; then ssh -o 'StrictHostKeyChecking no' -i $KEY_FILE USER@$MASTER_IP 'if [[ -f /tmp/icp_worker_scaler.sh ]]; then chmod a+x /tmp/icp_worker_scaler.sh; /tmp/icp_worker_scaler.sh a ${var.icp_edition} ${self.network.0.fixed_ip_v4}; fi'; fi"
        environment {
            MASTER_IP = "${openstack_compute_instance_v2.icp-master-vm.0.network.0.fixed_ip_v4}"
            USER = "${var.icp_install_user}"
            KEY_FILE = "${var.openstack_ssh_key_file}"
        }
    }

    provisioner "local-exec" {
        when    = "destroy"
        command = "ssh -o 'StrictHostKeyChecking no' -i $KEY_FILE $USER@$MASTER_IP 'if [[ -f /tmp/icp_worker_scaler.sh ]]; then chmod a+x /tmp/icp_worker_scaler.sh; /tmp/icp_worker_scaler.sh r ${var.icp_edition} ${self.network.0.fixed_ip_v4}; fi'"
        environment {
            MASTER_IP = "${openstack_compute_instance_v2.icp-master-vm.0.network.0.fixed_ip_v4}" #changed * to 0
            USER = "${var.icp_install_user}"
            KEY_FILE = "${var.openstack_ssh_key_file}"
        }
    }
}

resource "openstack_compute_instance_v2" "icp-master-vm" {
    count     = "${var.icp_num_masters}"        #....addition
    #count     = "${var.icp_num_masters["backend"]}"
    #count = "${var.instances["backend"]}"#......revert this line with the 1st if it dosnt work
    #name      = "${var.instance_prefix}-master-${random_id.rand.hex}"
    name      = "${format("${var.instance_prefix}-master-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_master_node}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    security_groups = ["${var.openstack_security_groups}"]
    availability_zone = "${var.openstack_availability_zone}"

    network {
        name = "${var.openstack_network_name}"
    }
    
    user_data = "${count.index > 0 ? "${data.template_file.bootstrap_init_subsequent_masters.rendered}" : "${data.template_file.bootstrap_init.rendered}"}" 

}

data "template_file" "bootstrap_init" {
    template = "${file("bootstrap_icp_master.sh")}"

    vars {
        icp_version = "${var.icp_version}"
        icp_architecture = "${var.icp_architecture}"
        icp_edition = "${var.icp_edition}"
        icp_download_location = "${var.icp_download_location}"
        icp_disabled_services = "${join(", ",formatlist("\"%s\"",var.icp_disabled_services))}"
        install_user_name = "${var.icp_install_user}"
        install_user_password = "${var.icp_install_user_password}"
        docker_download_location = "${var.docker_download_location}"

        vip_iface = "${var.vip_iface}"
        cluster_vip = "${var.cluster_vip}"
        proxy_vip_iface = "${var.proxy_vip_iface}"
        proxy_vip = "${var.proxy_vip}"
        if_HA = "${var.if_HA}"

	reg_path = "${var.reg_path}"
	registry_mount_src = "${var.registry_mount_src}"
	registry_mount_type = "${var.registry_mount_type}"
	registry_mount_options = "${var.registry_mount_options}"

	auth_audit_path = "${var.auth_audit_path}"
	audit_mount_src = "${var.audit_mount_src}"
	audit_mount_type = "${var.audit_mount_type}"
	audit_mount_options = "${var.audit_mount_options}"

	kub_audit_path = "${var.kub_audit_path}"
	kub_audit_mount_src = "${var.kub_audit_mount_src}"
	kub_audit_mount_type = "${var.kub_audit_mount_type}"
	kub_audit_mount_options = "${var.kub_audit_mount_options}"
	
    }
}

#.....For Subsequent masters .. script without ICP install cmds
data "template_file" "bootstrap_init_subsequent_masters" {
    template = "${file("bootstrap_icp_subsequent_masters.sh")}"

    vars {
        vip_iface = "${var.vip_iface}"
        if_HA = "${var.if_HA}"
	#reg_path = "${var.reg_path}"
	#registry_mount_src = "${var.registry_mount_src}"
	#auth_audit_path = "${var.auth_audit_path}"
	#audit_mount_src = "${var.audit_mount_src}"
	#kub_audit_path = "${var.kub_audit_path}"
	#kub_audit_mount_src = "${var.kub_audit_mount_src}"
	reg_path = "${var.reg_path}"
	registry_mount_src = "${var.registry_mount_src}"
	registry_mount_type = "${var.registry_mount_type}"
	registry_mount_options = "${var.registry_mount_options}"

	auth_audit_path = "${var.auth_audit_path}"
	audit_mount_src = "${var.audit_mount_src}"
	audit_mount_type = "${var.audit_mount_type}"
	audit_mount_options = "${var.audit_mount_options}"

	kub_audit_path = "${var.kub_audit_path}"
	kub_audit_mount_src = "${var.kub_audit_mount_src}"
	kub_audit_mount_type = "${var.kub_audit_mount_type}"
	kub_audit_mount_options = "${var.kub_audit_mount_options}"

        docker_download_location = "${var.docker_download_location}"
    }
}

data "template_file" "bootstrap_worker" {
    template = "${file("bootstrap_icp_worker.sh")}"

    vars {
        if_HA = "${var.if_HA}"
        docker_download_location = "${var.docker_download_location}"
    }
}
#---------------PROXY-------------------------------
resource "openstack_compute_instance_v2" "icp-proxy-vm" {
    count     = "${var.icp_num_proxy}"
    name      = "${format("${var.instance_prefix}-proxy-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_proxy_node}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    security_groups = ["${var.openstack_security_groups}"]
    availability_zone = "${var.openstack_availability_zone}"

    network {
        name = "${var.openstack_network_name}"
    }

    user_data = "${data.template_file.bootstrap_node.rendered}"			#bootstrap_node
    //local exec will cm for proxy if adding/deleting it is required.
}
data "template_file" "bootstrap_node" {
    template = "${file("bootstrap_icp_node.sh")}"		#use a common file for proxy, management, even worker if possible

    vars {
        vip_iface = "${var.vip_iface}"
        if_HA = "${var.if_HA}"
        docker_download_location = "${var.docker_download_location}"
    }
}
resource "null_resource" "icp-proxy-scaler" {
    triggers {
        proxies = "${join("|", openstack_compute_instance_v2.icp-proxy-vm.*.network.0.fixed_ip_v4)}"
    }

    connection {
        type            = "ssh"
        user            = "${var.icp_install_user}"
        #host            = "${openstack_compute_instance_v2.icp-proxy-vm.*.network.0.fixed_ip_v4}"
        host            = "${openstack_compute_instance_v2.icp-master-vm.0.network.0.fixed_ip_v4}"
        private_key     = "${file(var.openstack_ssh_key_file)}"
        timeout         = "15m"
    }

    #provisioner "file" {  				#check if u can add/delete proxy nodes
        #source      = "${path.module}/icp_proxy_scaler.sh"
        #destination = "/tmp/icp_proxy_scaler.sh"
    #}

    provisioner "file" {
        content     = "${join("|", openstack_compute_instance_v2.icp-proxy-vm.*.network.0.fixed_ip_v4)}"
        destination = "/tmp/icp_proxy_nodes.txt"
    }

    provisioner "file" {
        content     = "${file("${var.openstack_ssh_key_file}")}"
        destination = "/tmp/id_rsa.terraform"
    }
}

#---------------MANAGEMENT-------------------------------
resource "openstack_compute_instance_v2" "icp-management-vm" {
    count     = "${var.icp_num_management}"
    name      = "${format("${var.instance_prefix}-management-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_management_node}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    security_groups = ["${var.openstack_security_groups}"]
    availability_zone = "${var.openstack_availability_zone}"

    network {
        name = "${var.openstack_network_name}"
    }

    user_data = "${data.template_file.bootstrap_node.rendered}"		#bootstrap_node
    //local exec will cm for management if adding/deleting it is required.
}

resource "null_resource" "icp-management-scaler" {
    triggers {
        managements = "${join("|", openstack_compute_instance_v2.icp-management-vm.*.network.0.fixed_ip_v4)}"
    }

    connection {
        type            = "ssh"
        user            = "${var.icp_install_user}"
        #host            = "${openstack_compute_instance_v2.icp-management-vm.*.network.0.fixed_ip_v4}"
        host            = "${openstack_compute_instance_v2.icp-master-vm.0.network.0.fixed_ip_v4}"
        private_key     = "${file(var.openstack_ssh_key_file)}"
        timeout         = "15m"
    }

    #provisioner "file" {
        #source      = "${path.module}/icp_management_scaler.sh"
        #destination = "/tmp/icp_management_scaler.sh"
    #}

    provisioner "file" {
        content     = "${join("|", openstack_compute_instance_v2.icp-management-vm.*.network.0.fixed_ip_v4)}"
        destination = "/tmp/icp_management_nodes.txt"
    }

    provisioner "file" {
        content     = "${file("${var.openstack_ssh_key_file}")}"
        destination = "/tmp/id_rsa.terraform"
    }
}


#...........................................null resourse for master....................................

resource "null_resource" "icp-master-scaler" {
    triggers {
        masters = "${join("|", openstack_compute_instance_v2.icp-master-vm.*.network.0.fixed_ip_v4)}"
    }

    connection {
        type            = "ssh"
        user            = "${var.icp_install_user}"
        #host            = "${openstack_compute_instance_v2.icp-master-vm.*.network.0.fixed_ip_v4}"
        host            = "${openstack_compute_instance_v2.icp-master-vm.0.network.0.fixed_ip_v4}"
        private_key     = "${file(var.openstack_ssh_key_file)}"
        timeout         = "15m"
    }

    #provisioner "file" {					#commenting - as we wont be adding or removing master nodes
        #source      = "${path.module}/icp_master_scaler.sh"
        #destination = "/tmp/icp_master_scaler.sh"
    #}

    provisioner "file" {
        content     = "${join("|", openstack_compute_instance_v2.icp-master-vm.*.network.0.fixed_ip_v4)}"
        destination = "/tmp/icp_master_nodes.txt"
    }

    #commenting the below part as I want every vm to create it's own key. Not sure if this would conflict.
    provisioner "file" {
        content     = "${file("${var.openstack_ssh_key_file}")}"
        destination = "/tmp/id_rsa.terraform"
    }
}

#.............................................................................................................

resource "null_resource" "icp-worker-scaler" {
    triggers {
        workers = "${join("|", openstack_compute_instance_v2.icp-worker-vm.*.network.0.fixed_ip_v4)}"
    }

    connection {
        type            = "ssh"
        user            = "${var.icp_install_user}"
        #host            = "${openstack_compute_instance_v2.icp-master-vm.*.network.0.fixed_ip_v4}" #......... master?
        host            = "${openstack_compute_instance_v2.icp-master-vm.0.network.0.fixed_ip_v4}"
        private_key     = "${file(var.openstack_ssh_key_file)}"
        timeout         = "15m"
    }

    provisioner "file" {
        source      = "${path.module}/icp_worker_scaler.sh"
        destination = "/tmp/icp_worker_scaler.sh"
    }

    provisioner "file" {
        content     = "${join("|", openstack_compute_instance_v2.icp-worker-vm.*.network.0.fixed_ip_v4)}"
        destination = "/tmp/icp_worker_nodes.txt"
    }

    provisioner "file" {
        content     = "${file("${var.openstack_ssh_key_file}")}"
        destination = "/tmp/id_rsa.terraform"
    }
}
