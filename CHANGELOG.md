# Changelog

## [0.4.0](https://github.com/elelem-sh/openai/compare/v0.3.1...v0.4.0) (2026-11-19)


### Features

* stream over a kept-alive connection that retries busy servers ([6463020](https://github.com/elelem-sh/openai/commit/6463020dc62edab070b1aa753b7ff278f3504162))


### Bug Fixes

* say when a content filter stops a reply ([c02d2ec](https://github.com/elelem-sh/openai/commit/c02d2ec889c6be7f0a5cd3953df3c84f9169cd0d))
* say when a reply hits the output limit ([d8005bd](https://github.com/elelem-sh/openai/commit/d8005bdba722a44ce6492fb227d3cd087a807dda))

## [0.3.1](https://github.com/elelem-sh/openai/compare/v0.3.0...v0.3.1) (2026-11-18)


### Bug Fixes

* **deps:** accept the json that Ruby 4.0 ships ([3c856d4](https://github.com/elelem-sh/openai/commit/3c856d43e90bdcde09134d512bf60d4ba9db907e))

## [0.3.0](https://github.com/elelem-sh/openai/compare/v0.2.0...v0.3.0) (2026-11-16)


### Features

* accept model: from provider_options, fall back to ENV ([3f0360c](https://github.com/elelem-sh/openai/commit/3f0360c6ced4bbfaa21e9aa97cd79161ae01fdd4))


### Bug Fixes

* add rspec to Gemfile so bundle exec rspec runs at all ([15cbcc0](https://github.com/elelem-sh/openai/commit/15cbcc0d85b61c820b87d0be77ed86aa77a34ee6))
* empty OpenAI model and key settings count as unset, and a missing key fails at start ([c443200](https://github.com/elelem-sh/openai/commit/c44320031cfeb97155071601e9f0f021a0c5c647))
* OPENAI_BASE_URL points elelem-openai at any Chat Completions server (elelem-sh/elelem.sh[#26](https://github.com/elelem-sh/openai/issues/26)) ([387e821](https://github.com/elelem-sh/openai/commit/387e8219f38fb16b30e0883a71e3a3de0663558f))
* OPENAI_BASE_URL takes a trailing slash, an empty value is unset, and no key sends no header ([5dbb125](https://github.com/elelem-sh/openai/commit/5dbb125cf9119406745e945090a2502e0409f0c7))
* require elelem ~&gt; 0.12, the floor builtins/skills actually need ([d9e5880](https://github.com/elelem-sh/openai/commit/d9e588035a36a0122014695b8d8cd874048de63a))
* send earlier tool calls in the Chat Completions shape and omit empty tools (elelem-sh/elelem.sh[#26](https://github.com/elelem-sh/openai/issues/26)) ([9a51d90](https://github.com/elelem-sh/openai/commit/9a51d90cb687f292a089a67a2180abc818515f48))
