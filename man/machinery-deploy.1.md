
## deploy — Deploy Image to OpenStack Cloud

### SYNOPSIS

`machinery deploy` NAME -c CONFIG_FILE | --cloud-config=CONFIG_FILE
   [-i IMAGE_DIR | --image-dir=IMAGE_DIR]
   [-n CLOUD_IMAGE_NAME | --cloud-image-name=CLOUD_IMAGE_NAME]
   [-s | --insecure ]

`machinery` help [deploy]


### DESCRIPTION

The `deploy` command builds and deploys an image to an OpenStack cloud.
This command is particularly useful for testing, debugging, or for validation.


> #### NOTE: Set Password for Unattended Work
> Machinery asks for a password when sourcing the configuration
> file. This interrupts the work flow and the user has to enter
> this password.
> If you prefer to leave it uninterrupted and unattented, remove
> the following line in your cloud configuration file (see the `-c` option):
>
>   read -s OS_PASSWORD_INPUT 
>
> and set the password in the `OS_PASSWORD` variable:
>
>     export OS_PASSWORD=YOUR_PASSWORD


### ARGUMENTS

  * `NAME` (required):
    Name of the system description.


### OPTIONS

  * `-c CONFIG_FILE`, `--cloud-config=CONFIG_FILE` (required):
    Path to file where the cloud config (openrc.sh) is located.
    The configuration file is sourced by Machinery.

  * `-i IMAGE_DIR`, `--image-dir=IMAGE_DIR` (optional):
    Image file under specific path.

  * `-n CLOUD_IMAGE_NAME`, `--cloud-image-name=CLOUD_IMAGE_NAME` (required):
    Name of the image in the cloud.

  * `-s`, `--insecure` (optional):
    Allow to make "insecure" HTTPS requests, without checking the SSL
    certificate when uploading to the cloud.

### PREREQUISITES

 * The `deploy` command requires the packages `kiwi` for building the image
   and `python-glanceclient` for uploading the image to the cloud.

### SUPPORTED ARCHITECTURES

Machinery supports deploying x86_64 images on x86_64 systems.

### EXAMPLES

 * Build an image under the system description named `jeos`.
   Deploy it to the OpenStack cloud name `tux-cloud` by using the
   configuration file `openrc.sh` in directory `tux`:

   $ `machinery` deploy jeos -n tux-cloud -c tux/openrc.sh
