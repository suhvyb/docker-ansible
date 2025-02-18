#!/bin/bash

NETWORK_NAME="ansible_network"
CONTROLLER_CONTAINER="ansible-controller"
MANAGED_CONTAINER="ansible-managed"
CONTROLLER_IMAGE="ansible-controller-image"
MANAGED_IMAGE="ansible-managed-image"
SSH_KEY_DIR="$(pwd)/ssh-keys"
SSH_KEY="$SSH_KEY_DIR/id_rsa"

function show_help {
echo "Usage: $0 [command]"
echo "Commands:"
echo "  deploy   - Build and deploy the infrastructure"
echo "  destroy  - Destroy all infrastructure (containers, images, networks, and SSH keys)"
exit 1
}

if [ $# -eq 0 ]; then
echo "Error: No command provided."
show_help
fi

COMMAND=$1

case "$COMMAND" in
deploy)
# Create SSH key directory
mkdir -p "$SSH_KEY_DIR"

    # Generate SSH keys (if not exist)
    if [ ! -f "$SSH_KEY" ]; then
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -q
        echo "SSH keys generated."
    fi
    
    # Create Docker network
    docker network create "$NETWORK_NAME"
    echo "Docker network '$NETWORK_NAME' created."
    
    # Build the Ansible Controller Docker image
    docker build -t "$CONTROLLER_IMAGE" -f Dockerfile.controller .
    echo "Ansible Controller image built."
    
    # Build the Ansible Managed Node Docker image
    docker build -t "$MANAGED_IMAGE" -f Dockerfile.managed .
    echo "Ansible Managed Node image built."
    
    # Ask user for deployment confirmation
    echo -n "Would you like to deploy the containers? (yes/no): "
    read RESPONSE
    
    if [[ "$RESPONSE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        # Run the Managed Node container
        docker run -d --name "$MANAGED_CONTAINER" --network "$NETWORK_NAME" "$MANAGED_IMAGE"
        
        # Run the Controller container
        docker run -d --name "$CONTROLLER_CONTAINER" --network "$NETWORK_NAME" -v "$SSH_KEY_DIR:/root/.ssh" "$CONTROLLER_IMAGE"
        
        echo "Deployment complete. Containers running:"
        docker ps --format "table {{.ID}}	{{.Image}}	{{.Command}}	{{.CreatedAt}}	{{.Status}}	{{.Ports}}	{{.Names}}"
        
        # Provide user with SSH test steps
        echo -e "\nTest SSH from the Controller:"
        echo "  Enter the controller:"
        echo "    docker exec -it ansible-controller bash"
        echo "  Try SSH to the managed node:"
        echo -e "    ssh root@ansible-managed"
    else
        echo "Images built successfully. Here are the available images:"
        docker images --format "table {{.Repository}}	{{.Tag}}	{{.ID}}	{{.CreatedAt}}	{{.Size}}"
        echo "To manually deploy the containers, run the following commands:"
        echo "docker run -d --name $MANAGED_CONTAINER --network $NETWORK_NAME $MANAGED_IMAGE"
        echo "docker run -d --name $CONTROLLER_CONTAINER --network $NETWORK_NAME $CONTROLLER_IMAGE"
        exit 0
    fi
    ;;
destroy)
    echo "Destroying all infrastructure..."
    docker rm -f "$CONTROLLER_CONTAINER" "$MANAGED_CONTAINER"
    docker rmi "$CONTROLLER_IMAGE" "$MANAGED_IMAGE"
    docker network rm "$NETWORK_NAME"
    rm -rf "$SSH_KEY_DIR"
    echo "All infrastructure has been removed."
    ;;
*)
    echo "Error: Invalid command."
    show_help
    ;;
esac
