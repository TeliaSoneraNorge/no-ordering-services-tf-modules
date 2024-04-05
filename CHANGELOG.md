
# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased] - yyyy-mm-dd

## [1.1.23] - 2024-04-05
RDS module
- new variable added: `ca_cert_identifier` with default value `rds-ca-rsa2048-g1`

## [1.1.22] - 2023-11-21
RDS module 
 - new variable added: `copy_tags_to_snapshot`

## [1.1.21] - 2023-11-15
RDS module upgraded due to aws provider 5 support

## [1.1.20] - 2023-09-15
AWS Elasticache refactoring. To keep code simple and have more flexibility, redis and memcahced were split into own <br> 
modules:
 - previous code temporary rollbacked
 - new memcached introduced as own module

## [1.1.18] - 2023-07-018
ECS task handler lambda bug fix where exception was thrown if failing task was started by scheduler 

## [1.1.17] - 2023-06-01
Ability to configure target group stickiness of type app_cookie in ECS fargate service module.

## [1.1.13] - 2023-04-24
ECS task failing handler

### Added
- Terraform/Python code to shutdown or notify about service constantly failing to start
- Terraform code implementing ECS deployment circuit breaker feature

## [1.1.13] - 2023-04-11
ECS task definitions cleaner, checking TF state references fix

## [1.1.12] - 2023-04-11
ECS task definitions cleaner fix, checking TF state references

## [1.1.11] - 2023-03-27
Added ECS task definitions cleaner

## [1.1.10] - 2023-02-15
Changes related to redis sub-module.

### Added
- [CHANGELOG.md](https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/blob/master/CHANGELOG.md)

### Changed
- [SUB-MODULE, REDIS](https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/issues/38)
  Terraform deprecated variables replaced
- Unused sub-module parts removed

### Fixed

## [1.1.9]

[unreleased]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.23...master

[1.1.23]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.22...v1.1.23

[1.1.22]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.21...v1.1.22

[1.1.21]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.20...v1.1.21

[1.1.20]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.19...v1.1.20

[1.1.18]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.17...v1.1.18

[1.1.17]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.14...v1.1.17

[1.1.14]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.13...v1.1.14

[1.1.13]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.12...v1.1.13

[1.1.12]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.11...v1.1.12

[1.1.11]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.10...v1.1.11

[1.1.10]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.9...v1.1.10

[1.1.9]: https://github.com/TeliaSoneraNorge/no-ordering-services-tf-modules/compare/v1.1.8...v1.1.9
