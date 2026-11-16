As a `person who wants to use OpenAI or a compatible server from
elelem`, I `want a README and clear RubyGems links for elelem-openai`,
so that `I can point it at my server without reading the code and find
the docs and backlog from the gem page`.

# SYNOPSIS

Add a README, and point the gem's RubyGems links at elelem.sh and this
repository's backlog.

# DESCRIPTION

Two small changes that both shape what a newcomer sees first.

## README

The repository has no README. It should cover:

* Install, and selecting the provider: `-p openai` and `--model NAME`.
* `OPENAI_API_KEY`, `OPENAI_MODEL` (default `gpt-4o`) and
  `OPENAI_BASE_URL` (default `https://api.openai.com/v1`).
* Compatible servers: with `OPENAI_BASE_URL` set, no key is required,
  so a local Chat Completions server works; an example.
* That a set but empty variable counts as unset.
* A link to https://elelem.sh/plugins/openai/ for the full guide.

The elelem.sh plugin page can be the source for the text. Show commands
without a leading `$`, so they can be pasted.

## Gem metadata

RubyGems shows `homepage_uri` and the other `metadata` links on every
gem page. Today `elelem-openai.gemspec` sets `spec.homepage`
to the site root (https://elelem.sh) and sets only `homepage_uri`,
`source_code_uri`, `allowed_push_host` and
`rubygems_mfa_required`.
There is no documentation, bug tracker or changelog link.

Proposed change:

```ruby
spec.homepage = "https://elelem.sh/plugins/openai/"
spec.metadata["homepage_uri"] = spec.homepage
spec.metadata["source_code_uri"] = "https://github.com/elelem-sh/openai"
spec.metadata["documentation_uri"] = spec.homepage
spec.metadata["bug_tracker_uri"] = "https://github.com/elelem-sh/openai/tree/main/.agents/backlog"
spec.metadata["changelog_uri"] = "https://github.com/elelem-sh/openai/blob/main/CHANGELOG.md"
```

The original proposal pointed `bug_tracker_uri` at GitHub Issues on
elelem-sh/elelem.sh, filtered by label. That no longer fits: the
project is moving its backlog out of GitHub Issues and into
`.agents/backlog` story files in each repository, so the bug tracker
link points at this repository's backlog directory instead.

/man/openai/ redirects to /plugins/openai/ on elelem.sh, so a
separate documentation_uri adds nothing. Point both at the plugin page.
CHANGELOG.md exists on main, so the changelog link works today.

Keep `allowed_push_host` and `rubygems_mfa_required` as they are.
RubyGems only shows the new links after the next release.

# SEE ALSO

* [ ] lib/elelem/openai.rb:11-27 - provider block and environment
* [ ] exe/elelem-openai
* [ ] elelem-openai.gemspec:13 - spec.homepage and metadata
* [ ] https://elelem.sh/plugins/openai/ - source for README text
* [ ] Formerly elelem-sh/elelem.sh#23
* [ ] Formerly elelem-sh/elelem.sh#41

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] README.md exists and covers the points above
* [ ] Defaults in the README match the code
* [ ] Commands in the README have no leading `$`
* [ ] `spec.homepage` and `homepage_uri` are https://elelem.sh/plugins/openai/
* [ ] `bug_tracker_uri` points at this repository's `.agents/backlog`,
      not at GitHub Issues
* [ ] `changelog_uri` and `source_code_uri` point at this repository
* [ ] `gem build` succeeds and `gem spec` on the built gem shows every
      link
