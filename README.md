# Rearc take-home

The script to download the data from bls website and the ACS API (i.e. parts 1 + 2) is data_scraper.py 
(note: wget is required to successfully run it)

The data is uploaded to [this bucket](https://s3.console.aws.amazon.com/s3/buckets/ryanfore-rearc?region=us-east-1&tab=objects).

ryan_rearc.ipynb is where the analysis for part 3 is done.

Running `terraform plan && terraform apply -auto-approve` will create:
- The public-read bucket where the scraped data is stored
- Two ECR repositories that will contain the docker images used in the lambda functions
to scrape + analyze the data
- Two dummy images just so that the lambda functions can be instantiated (as there already needs to be an image 
in place when terraform attempts to create the lambda functions)
- Theoretically, one lambda function to scrape the data, and one to generate the reports. As of yet, neither of these
functions are actually tied to an event (indeed, since I was unable to actually create lambda functions due to 
my AWS account being locked down due to potential fraud, and as such, I commented out the code). There's a significant
chance that to complete step 4, the IAM policy used for the lambda functions would need to be adjusted. 

The actual code for the two lambda functions lives in the lambda_reports + lambda_scraper folders.
Running the shell script in those two folders will create the docker images containing the code and
the necessary packages for each function, and upload it to ECR


## Room for improvement
(Besides, you know, actually finishing part 4)

- Better dependency management tools, namely specifying versions for the dependencies, and using a tool
something that results in a lock file (e.g. virtualenv, or my preferred tool, Poetry)
- Better setup for the bucket used to store the data (e.g. bucket versioning and lifecycle control)
- Less hard coding of paths, especially around the process of ECR + image creation. For example if you want to
change the name of a repository, you have to change it both in the backend.tf file and in the shell scripts used
later to build and upload the images. Ideally there would be some sort of env variable that would be shared across
the 2 files. Or I could change the create_image shell scripts into one script that takes a directory name and
ECR repository name as inputs in order to make to code more DRY
- Somewhat relatedly, probably break up the backend.tf into several files, e.g. providers.tf, iam_users_policies.tf, 
s3.tf, etc.  Especially important if this repo would be built upon to add more functionality.
- Set everything up with CI/CD using something like CircleCI or Travis. Set it up so that any time a new branch
is pushed to master, the Terraform changes are automatically applied, and the docker images are automatially build
and deployed
- If the files downloaded were larger / more numerous, would probably want to set it up so that they were only downloaded
if they had been modified, rather than downloading everything and then syncing it to S3
- Write tests for everything