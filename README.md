# Something

## Installation
First put your data downloaded from [BroadInstitute](https://bbbc.broadinstitute.org/BBBC021) into the `data` folder. You should download all images and all csv files.

Then unzip them (you can you for this for example: `for z in *.zip; do unzip "$z"; done`.

To check if you have all of the images, run the following command in the data folder:
```bash
sh missing.sh BBBC021_v1_image.csv
```
