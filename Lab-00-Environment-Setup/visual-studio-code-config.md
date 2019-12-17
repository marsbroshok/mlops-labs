## Using the TFX/KFP development image with Visual Studio Code

In the first section of the setup you created a custom container image to use with **AI Platform Notebooks**. 

You can also use this image with Visual Studio Code for both local and remote development.  The following instructions were tested on MacOS but should be transferable to other platforms.

### Preparing your MacOS workstation
1. Install and initialize [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstart-macos)

1. [Install Docker Desktop for Mac](https://docs.docker.com/docker-for-mac/install/)

1. [Install Visual Studio Code](https://code.visualstudio.com/download)

1. [Install Visual Studio Code Remote Development Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)


### Configuring Visual Studio Code for local development
1. Clone this repo on your workstation
2. In the repo's root create the `.devcontainer` folder.
3. In the `.devcontainer` folder create a Dockerfile using the following template. Make sure to replace the `[YOUR_PROJECT_NAME]` placeholder with you project id.
```
FROM gcr.io/[YOUR_PROJECT_NAME/tfx-kfp-dev:latest
```
4. In the `.devcontainer` folder create the `devcontainer.json` file. Refer to https://github.com/microsoft/vscode-dev-containers/tree/master/containers/docker-existing-dockerfile for more information about the configuration options. The below configuration tells VSC to create an image using the provided Dockerfile and install Microsoft Python extension after the container is started.
```
{
	"name": "Existing Dockerfile",
	"context": "..",
	"dockerFile": "Dockerfile",
	"settings": { 
		"terminal.integrated.shell.linux": null
	},
	"extensions": ["ms-python.python"]
}
```
5. From the Visual Studio Code command pallete (**[SHIFT][COMMAND][P]**) select **Remote-Containers:Open Folder in Container**. Find the root folder of the repo. After selecting the folder, Visual Studio Code downloads your image, starts the container and installs the Python extension to the container. 

### Configuring Visual Studio Code for remote development
1. Create an AI Platform Notebook using the development image as described in the **Creating an AI Platform Notebook** section.
2. Make sure you can connect to the AI Platform Notebook's vm instance from your workstation using `ssh`
```
gcloud compute ssh [YOUR AI PLATFORM NOTEBOOK VM NAME] --zone [YOUR ZONE]
```
2. Create a configuration for the VM in your `~/.ssh/config`
```
Host [YOUR CONFIGURATION NAME]
  User [YOUR USER NAME]
  HostName [YOUR VM'S IP ADDRESS]
  IdentityFile /Users/[YOUR USER NAME]/.ssh/google_compute_engine
```
3. Test the configuration
```
ssh [YOUR CONFIGURATION NAME]
```
4. You can now connect to AI Platform Notebook using a SSH tunnel. 
  - Update the `docker.host` property in your user or workspace Visual Studio Code `settings.json` as follows
  ```
  "docker.host":"tcp//localhost:23750"
  ```
  - From a local terminal set up an SSH tunnel
  ```
  ssh -NL localhost:23750:/var/run/docker.sock [YOUR CONFIGURATION NAME] 
  ```

5. In Visual Studio Code bring up the **Command Palette** (**[SHIFT][COMMAND][P]**)) and type in **Remote-Containers** for a full list of commands. Choose **Attach to Running Container** and select your ssh configuration.


