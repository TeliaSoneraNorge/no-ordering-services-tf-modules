# no-ordering-services-tf-modules

A collection of terraform modules used by ordering/product domain that have not been published to the registry because are specific to the domain needs.

# Release

Running the [publish-to-s3 workflow](https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/actions/workflows/publish-to-s3.yml) will zip the modules and upload to S3 and will be available `s3://no-ordering-services-tf-modules/latest/`.

To release a new version, create a release with a tag in Github, document the changes in the release, and then run the publish-to-s3 workflow by specifying the reference tag version. This will result publishing to a versioned sub-directory, i.e. `s3://no-ordering-services-tf-modules/v3.0.1/`.

# Use from terraform

Example:

```terraform
module "ecr_policy" {
  source = "s3::https://no-ordering-services-tf-modules.s3.eu-west-1.amazonaws.com/v1.1.33/ecr-policy.zip"
}
```