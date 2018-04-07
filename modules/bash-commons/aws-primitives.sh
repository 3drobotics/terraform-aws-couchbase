#!/bin/bash

set -e

# Look up the given path in the EC2 Instance metadata endpoint
function lookup_path_in_instance_metadata {
  local readonly path="$1"
  curl --silent --show-error --location "http://169.254.169.254/latest/meta-data/$path/"
}

# Look up the given path in the EC2 Instance dynamic metadata endpoint
function lookup_path_in_instance_dynamic_data {
  local readonly path="$1"
  curl --silent --show-error --location "http://169.254.169.254/latest/dynamic/$path/"
}

# Get the private IP address for this EC2 Instance
function get_instance_private_ip {
  lookup_path_in_instance_metadata "local-ipv4"
}

# Get the public IP address for this EC2 Instance
function get_instance_public_ip {
  lookup_path_in_instance_metadata "public-ipv4"
}

# Get the private hostname for this EC2 Instance
function get_instance_private_hostname {
  lookup_path_in_instance_metadata "local-hostname"
}

# Get the public hostname for this EC2 Instance
function get_instance_public_hostname {
  lookup_path_in_instance_metadata "public-hostname"
}

# Get the ID of this EC2 Instance
function get_instance_id {
  lookup_path_in_instance_metadata "instance-id"
}

# Get the region this EC2 Instance is deployed in
function get_instance_region {
  lookup_path_in_instance_dynamic_data "instance-identity/document" | jq -r ".region"
}

# Get the availability zone this EC2 Instance is deployed in
function get_ec2_instance_availability_zone {
  lookup_path_in_instance_metadata "placement/availability-zone"
}

# Get the tags for the given intance and region
function get_instance_tags {
  local readonly instance_id="$1"
  local readonly instance_region="$2"

  aws ec2 describe-tags \
    --region "$instance_region" \
    --filters "Name=resource-type,Values=instance" "Name=resource-id,Values=$instance_id"
}

# Describe the given ASG in the given region
function describe_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  aws autoscaling describe-auto-scaling-groups --region "$aws_region" --auto-scaling-group-names "$asg_name"
}

# Describe the EC2 Instances in the given ASG in the given region
function describe_instances_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  aws ec2 describe-instances --region "$aws_region" --filters "Name=tag:aws:autoscaling:groupName,Values=$asg_name" "Name=instance-state-name,Values=pending,running"
}