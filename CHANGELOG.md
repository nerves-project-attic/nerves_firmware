# Changelog

## v0.4.0 (2017-05-04)

- Support chunked streaming direct to fwup (thanks @mobileoverlord and @fhunleth)
- Support fwup's signing process for firmware (thanks @connorrigby)
- Add finalize/1 (mostly to support `nerves_firmware_http` streaming state)

## v0.3.0 (2017-02-22)

- Converted compile-time config to runtime
- Fixed tests to work with newer fwup (>= 0.11.0)
- bumped to elixir 1.4 & fixed warnings

## v0.2.0 (2016-06-23)

- Split nerves_firmware_http out, depends on this module
- Cleaned up documentation somewhat
