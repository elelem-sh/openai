# Changelog

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
