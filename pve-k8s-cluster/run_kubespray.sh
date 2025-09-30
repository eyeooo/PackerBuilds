#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define paths
KUBESPRAY_DIR="/home/dev/kubespray"
INVENTORY_DIR="${KUBESPRAY_DIR}/inventory/my-cluster"
INVENTORY_FILE="${INVENTORY_DIR}/inventory.ini"
TEMP_INVENTORY_FILE="/home/dev/inventory.ini" # Location where Terraform uploads the file

echo "--- Starting Kubespray Deployment at $(date) ---"

echo "Waiting for 30 seconds for network to stabilize..."
sleep 30

# 1. Clone Kubespray repo if it doesn't exist
if [ ! -d "$KUBESPRAY_DIR" ]; then
  echo "Cloning Kubespray..."
  git clone --branch v2.28.1 https://github.com/kubernetes-sigs/kubespray.git $KUBESPRAY_DIR
else
  echo "Kubespray directory already exists. Skipping clone."
fi

cd $KUBESPRAY_DIR

# 2. Set up inventory directory from sample if it doesn't exist
echo "Setting up inventory directory..."
if [ ! -d "$INVENTORY_DIR" ]; then
  echo "Copying sample inventory to my-cluster..."
  cp -rfp inventory/sample "$INVENTORY_DIR"
else
  echo "Inventory directory my-cluster already exists."
fi

# 3. Move the Terraform-generated inventory file into place, overwriting the sample.
echo "Moving dynamic inventory file into place..."
if [ -f "$TEMP_INVENTORY_FILE" ]; then
  mv "$TEMP_INVENTORY_FILE" "$INVENTORY_FILE"
else
  echo "WARNING: Temporary inventory file ${TEMP_INVENTORY_FILE} not found."
fi

# 4. Set up Python virtual environment and install dependencies
echo "Setting up Python virtual environment and dependencies..."
if [ ! -d "venv" ]; then
  python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt

# 5. Run the Kubespray playbook
echo "Running Ansible playbook... This will take a while."
ansible-playbook -i $INVENTORY_FILE --become --become-user=root cluster.yml

echo "--- Kubespray Deployment Finished at $(date) ---"