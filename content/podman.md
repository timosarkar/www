+++
title = "Podman"
date = 2024-12-06T13:35:03+01:00
+++

Podman is really cool. I have just recently stumbled upon it, since I
was looking for a good docker alternative. It is really fast and lightweight.
Here are my personal notes on Podman.

## Installing Podman

To install Podman you need to be on an Unix like Debian or Ubuntu. I am on
Ubuntu so this will be the install command for me.

```
sudo apt-get install podman -y
```

After that you can verify the installation with the following command.

```
podman --version
```

## Creating an Image

To create an Image, we will need to create a Dockerfile. Here is mine.

```
FROM debian:latest

RUN apt update && \
    apt install -y git curl && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["bash"]
```

This will pull the latest version of Debian, install Git and Curl and then
launch a bash shell. To build the image from this Dockerfile we can run this command.

```
podman build --tag <name-of-image-here> .
```

After that you can list all available images with `podman images`.

## Running a Container

To create and run a container based on the newly created image, you can
run this command.

```
podman run --interactive -t <name-of-image-here> 
```
