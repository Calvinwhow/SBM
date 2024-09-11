import subprocess
import sys
import os
import platform

class CalvinSBM:
    """
    CalvinSBM is a class for orchestrating neuroimaging data processing using Docker.
    """
    @staticmethod
    def docker_build_and_push():
        """
        Builds image to be compatible with amd64 and arm64 chip architectures. 
        Pushes to repository calvinwhow/freesurfer
        
        Uses relative path of the dockerfile.
        """
        subprocess.run(f"docker buildx build --platform linux/amd64,linux/arm64 -f dockerfiles/Dockerfile.freesurfer -t calvinwhow/freesurfer:latest --push .")

    @staticmethod
    def pull_docker_image(image_name):
        """
        Pulls the Docker image from the specified repository.

        Args:
            image_name (str): The name of the Docker image to pull.
        """
        try:
            print(f"Pulling Docker image: {image_name}...")
            subprocess.run(f"docker pull {image_name}", shell=True, check=True)
            print(f"Docker image {image_name} pulled successfully.")
        except subprocess.CalledProcessError as e:
            print(f"An error occurred while pulling the Docker image: {e}")
            sys.exit(1)

    @staticmethod
    def setup_docker_environment(image_name, os=None):
        """
        Prepares the Docker environment by pulling the image and setting up for subsequent use.

        Args:
            image_name (str): The name of the Docker image to pull.
            os (str): OS being used
                Paradoxically, specifying os=mac results in Mac M1 failing to run these files. 
                Thus, given that Docker emulates the x86 architecture, you can specify windows if getting "cannot find x86" errors. 
                This will allow Docker to emulate the particular x86 chip architecture, as it generally does on Mac M1 using the amd64 chip. 
        """
        if os == 'mac': subprocess.run(f"docker pull --platform linux/arm64 {image_name}", shell=True, check=True)
        elif os == 'windows': subprocess.run(f"docker pull --platform linux/amd64 {image_name}", shell=True, check=True)
        else: CalvinSBM.pull_docker_image(image_name)
        print(f"Docker environment ready with image: {image_name}")

    @staticmethod
    def convert_path_for_docker(path):
        """
        Converts a Windows path to a Docker-compatible path (if running on Windows).

        Args:
            path (str): The original file system path.

        Returns:
            str: The converted path suitable for Docker volume mounting.
        """
        if platform.system() == "Windows":
            return path.replace("\\", "/")
        return path

    @staticmethod
    def run_docker_script(image_name, script_path, data_dir, os=None):
        """
        Runs the Docker container with the mounted data directory and executes the script inside it.

        Args:
            image_name (str): The name of the Docker image to run.
            script_path (str): The path to the script inside the container to be executed.
            data_dir (str): The local path to the BIDS dataset directory.
            os (str): OS being used
                Paradoxically, specifying os=mac results in Mac M1 failing to run these files. 
                Thus, given that Docker emulates the x86 architecture, you can specify windows if getting "cannot find x86" errors. 
                This will allow Docker to emulate the particular x86 chip architecture, as it generally does on Mac M1 using the amd64 chip. 
        """
        try:
            docker_data_dir = CalvinSBM.convert_path_for_docker(data_dir)
            docker_script_path = CalvinSBM.convert_path_for_docker(script_path)
            
            print(f"Running Docker container with script: {script_path}")
            if os == 'mac':
                subprocess.run([
                    "docker", "run", "--platform", "linux/arm64", "--rm", 
                    "-v", f"{docker_data_dir}:/data",  # Mount local data directory to /data in the container
                    "-v", f"{docker_script_path}:/scripts/run_reconall.sh",  # Mount script to /scripts in the container
                    image_name, 
                    "/bin/bash", "/scripts/run_reconall.sh"  # Run the script inside the container
                ], check=True)
            elif os == 'windows':
                subprocess.run([
                    "docker","run", "--platform", "linux/amd64", "--rm", 
                    "-v", f"{docker_data_dir}:/data",  # Mount local data directory to /data in the container
                    "-v", f"{docker_script_path}:/scripts/run_reconall.sh",  # Mount script to /scripts in the container
                    image_name, 
                    "/bin/bash", "/scripts/run_reconall.sh"  # Run the script inside the container
                ], check=True)
            else: 
                subprocess.run([
                    "docker", "run", "--rm", 
                    "-v", f"{docker_data_dir}:/data",  # Mount local data directory to /data in the container
                    "-v", f"{docker_script_path}:/scripts/run_reconall.sh",  # Mount script to /scripts in the container
                    image_name, 
                    "/bin/bash", "/scripts/run_reconall.sh"  # Run the script inside the container
                ], check=True)
            print(f"Script {script_path} executed successfully inside Docker container.")
        except subprocess.CalledProcessError as e:
            print(f"An error occurred while running the Docker container: {e}")
            sys.exit(1)