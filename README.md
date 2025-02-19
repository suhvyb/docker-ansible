# Ansible Docker Setup

This project sets up an **Ansible Controller** and an **Ansible Managed Node** inside Docker containers. The controller manages the managed node over SSH using generated SSH keys.

## Features
- **Automated setup**: Builds and deploys infrastructure using a single script.
- **Custom network**: Containers communicate over a dedicated Docker network.
- **Persistent SSH keys**: Secure authentication for Ansible operations.
- **Easy cleanup**: Remove all containers, images, networks, and SSH keys with a single command.

## Prerequisites
Ensure you have the following installed on your system:
- Docker
- Docker Compose (optional)
- Bash (for running the script)

## Setup Instructions

### 1. Clone the Repository
```sh
git clone https://github.com/your-repo/ansible-docker-setup.git
cd ansible-docker-setup
```

### 2. Make the `setup.sh` File Executable
Before running the setup script, give it execution permissions:
```sh
chmod +x setup.sh
```

### 3. Deploy Infrastructure
Run the setup script to build the Docker images and deploy the infrastructure:
```sh
./setup.sh deploy
```
The script will prompt:
- **Would you like to deploy the containers?**
  - Type `yes` or `y` to deploy the containers.
  - Type `no` or `n` to only create the network and build the images.

### 4. Verify Running Containers
After deployment, check if the containers are running:
```sh
docker ps
```
You should see `ansible-controller` and `ansible-managed` listed.

## Connecting to the Ansible Controller
To access the Ansible Controller container:
```sh
docker exec -it ansible-controller bash
```

From inside the container, you can SSH into the managed node:
```sh
ssh root@ansible-managed
```

To find out the IP address of your ansible-managed container, from your local machine run:
```sh
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ansible-managed
```

Example inventory.ini file:
```sh
[managed]
ansible-managed ansible_host=172.19.0.2 ansible_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa ansible_python_interpreter=/usr/bin/python3
```

## Cleanup
To remove all containers, images, networks, and SSH keys, run:
```sh
./setup.sh destroy
```

This will:
- Stop and remove the **Ansible Controller** and **Managed Node** containers.
- Delete the **Docker network**.
- Remove all **generated SSH keys**.
- Delete the **Dockerfiles**.

## Manual Deployment Commands
If you chose **not** to deploy the containers automatically, you can manually start them using:
```sh
docker run -d --name ansible-managed --network ansible_network ansible-managed-image

docker run -d --name ansible-controller --network ansible_network ansible-controller-image
```

## Notes
- The SSH private key is now built into the **Ansible Controller** image, so no external volume mount is needed.
- The Docker network `ansible_network` allows the two containers to communicate securely.

Enjoy automating with Ansible! 🚀
