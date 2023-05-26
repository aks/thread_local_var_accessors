2023-05-04: Version 1.0.0
- added support for default values:
  - renamed `tlv_new` to `tlv_init` (leaving `tlv_new` as an alias)
  - added new instance methods: `tlv_default`, `tlv_set_default`
  - updated docs to explain how defaults are cross-threads
- updated the README.md
