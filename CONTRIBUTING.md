# How you can contribute to hermez_sdk 

Hi nice to see you here. 🙌🎉

Thank you for taking the time to contribute to this package ! 👍

This document should be a set of guidelines that can help you to create a meaningful
pull request or issue. Don't see this as any kind of rules, this is a living document,
so if you have an idea how to optimize this propose changes in a pull request.

## How do I propose a change?

Changes to the public SDK should be done via an issue. So we can discuss the proposed 
changes before you put any work into them.

If you are fixing a bug, you can just submit a pull request. We do recommend filing an issue
as well to get an overview what it is that you are fixing.
This is helpful in case we don’t accept that specific fix but want to keep
track of the issue.

## What do I do before creating a pull request

1. Fork the repository and branch out of `master`, prefixing your branch's name with `feature/`, `bug/` or `task/` to indicate the scope of the PR.
1. Install all dependencies (`flutter packages get` or `pub get`)
1. Ensure you have a meaningful PR name using the [imperative mood](https://chris.beams.io/posts/git-commit/#imperative) as all your commits will be squashed upon merge and the PR's name will be used as the merge commit's message.
1. If the PR can be broken down into multiple meaningful PRs please do so so that it is easier to review.
1. If you’ve fixed a bug or added code that should be tested, add tests!
1. If you've changed the public SDK, make sure to update/add documentation (for now that is the [Readme](README.md))
1. If you've made breaking changes give us a heads up in the pull request. Try to provide a compatibility path for the deprecated code and if necessary provide migration instructions in the [Readme](README.md).
1. Format your code (`dartfmt -w .`)
1. Analyze your code (`flutter analyze`)
1. Create the Pull Request
1. Verify that all status checks are passing

While the prerequisites above must be satisfied prior to having your
pull request reviewed, the reviewer(s) may ask you to complete additional
design work, tests, or other changes before your pull request can be ultimately
accepted.

## Getting in Touch

If you want to just ask a question or get feedback on an idea you can post it
on [Discord](https://discord.com/invite/AczuUXDA2N).

## License

By contributing to hermez_sdk, you agree that your contributions will be licensed
under its [GPL v3 license](LICENSE).
