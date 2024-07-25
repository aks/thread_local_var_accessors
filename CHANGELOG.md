2024-07-24: Version 1.4.0
- updated concurrent-ruby to 1.3.3 (from 1.2.2)
- updated development gems to latest versions
- removed innocuous misplaced value
- simplified the CI release steps

2024-05-09: Version 1.3.1
- DRYed up the `tlv_default` method
- Changed CI to support "release" task on the main branch
- Added more tasks to the Rakefile
- Added RELEASES to the version file.
- Updated the ruby version to 3.1

2023-05-04: Version 1.0.0
- added support for default values:
  - renamed `tlv_new` to `tlv_init` (leaving `tlv_new` as an alias)
  - added new instance methods: `tlv_default`, `tlv_set_default`
  - updated docs to explain how defaults are cross-threads
- updated the README.md
