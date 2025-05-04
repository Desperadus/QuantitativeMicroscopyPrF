# Something

## Installation
First put your data downloaded from [BroadInstitute](https://bbbc.broadinstitute.org/BBBC021) into the `data` folder. You should download all images and all csv files.

Then unzip them (you can you for this for example: `for z in *.zip; do unzip "$z"; done`.)

To check if you have all of the images, run the following command in the data folder:
```bash
sh missing.sh BBBC021_v1_image.csv
```

Then create folders `WeeksN` for N in 1 to 10 and move given folders indside of them. 

Your following structure of the `data` folder should look like this:
```
.
├── BBBC021_v1_image.csv
├── BBBC021_v1_moa.csv
├── missing.sh
├── show.sh
├── Week1
│   ├── Week1_22123
│   ├── Week1_22141
│   ├── Week1_22161
│   ├── Week1_22361
│   ├── Week1_22381
│   └── Week1_22401
├── Week10
│   ├── Week10_40111
│   ├── Week10_40115
│   └── Week10_40119
├── Week2
│   ├── Week2_24121
│   ├── Week2_24141
    .
    .
    .
```