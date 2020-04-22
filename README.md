# Lerna Workflow Example

## Summary

In this article we explore how we can use **Lerna 3.20.2** to manage an application. We use Lerna to break down the codebase into small packages and to help us go through the different stages of the development cycle.

⚠️While this article can be used as a starting point for designing alternative worklows, it is important to note that the workflow described here is **incompatible with the "Conventional Commits" specification**. See the following resources:

- https://stackoverflow.com/q/61144530/1244884
- https://github.com/lerna/lerna/issues/2536
- https://github.com/customcommander/lerna-prerelease-conventional-commits

---

_What follows is based on observations and is completely reproducible. The repository in the case study is available as a Docker container and all steps are fully automated. (See Appendix.)_

---

## Case Study: Managing a website

The website development cycle is powered by a Lerna-managed monorepo. The codebase is split into several sub packages of which the website is one of them and depends on the other packages:

* lib_a
* lib_b
* lib_c
* website (depends on the three packages above)

```
dev
|-- packages
|   |-- lib_a             1.0.0-alpha.0
|   |-- lib_b             1.0.0-alpha.0
|   |-- lib_c             1.0.0-alpha.0
|   |-- website           1.0.0-alpha.0
|       |-- lib_a         1.0.0-alpha.0
|       |-- lib_b         1.0.0-alpha.0
|       |-- lib_c         1.0.0-alpha.0
|-- package.json
|-- lerna.json
```

### Workflow Summary

The `website` package is our main releasable artifact and will be released every two weeks as minor updates (e.g. 1.0.0, 1.1.0, 1.2.0, etc.). Patch releases (e.g. 1.0.1, 1.0.2, etc.) can happen to fix production issues.

Major releases (e.g. 2.0.0, 3.0.0, etc.) **shall not** happen. In this case study the website is similar to an ever-green browser; it gets updated unconditionally. Therefore using major updates as a way to protect users from breaking changes makes no sense in this context.

### Workflow Details

New features and bug fixes go through three stages. Each stage has it own branch and versioning scheme:

|             | Alpha                | Beta                | Production   |
|:------------|:---------------------|:--------------------|:-------------|
| **Branch**  | integration          | release/*           | master       |
| **Version** | *e.g.* 1.0.0-alpha.0 | *e.g.* 1.0.0-beta.0 | *e.g.* 1.0.0 |

#### Alpha Stage

At the start of a new development cycle, all packages are minor bumped.

|         | lib_a         | lib_b         | lib_c         | website       |
|:--------|:--------------|:--------------|:--------------|:--------------|
| Cycle 1 | 1.0.0-alpha.0 | 1.0.0-alpha.0 | 1.0.0-alpha.0 | 1.0.0-alpha.0 |
| Cycle 2 | 1.1.0-alpha.0 | 1.1.0-alpha.0 | 1.1.0-alpha.0 | 1.1.0-alpha.0 |
| Cycle 3 | 1.2.0-alpha.0 | 1.2.0-alpha.0 | 1.2.0-alpha.0 | 1.2.0-alpha.0 |
| ...     | ...           | ...           | ...           | ...           |

Developers implement new features and bug fixes in the **integration** branch. The CI/CD pipeline publishes packages on a per commit basis.

Example: at the end of the Alpha stage of Cycle 1:

|       | # commits | version       |
|:------|:----------|:--------------|
| lib_a | 3         | 1.0.0-alpha.3 |
| lib_b | 1         | 1.0.0-alpha.1 |
| lib_c | 0         | 1.0.0-alpha.0 |


The public-facing website *never* consumes alpha packages!

#### Beta Stage

After two weeks of development it is time to release to our beta testers at http://beta.example.com.

Developers cut a new release branch from the **integration** branch and name the release branch after the current minor version e.g. **release/v1.0.0**, **release/v1.1.0**, etc.

The CI/CD pipeline is configured to promote all alpha packages to beta packages:

|         | Alpha         | Beta         |
|:--------|:--------------|:-------------|
| lib_a   | 1.0.0-alpha.3 | 1.0.0-beta.0 |
| lib_b   | 1.0.0-alpha.1 | 1.0.0-beta.0 |
| lib_c   | 1.0.0-alpha.0 | 1.0.0-beta.0 |

#### Production Stage

After two weeks of beta testing and with no major issues reported, it is time to promote our beta packages to production:

|         | Beta         | Production |
|:--------|:-------------|:-----------|
| lib_a   | 1.0.0-beta.0 | 1.0.0      |
| lib_b   | 1.0.0-beta.0 | 1.0.0      |
| lib_c   | 1.0.0-beta.0 | 1.0.0      |


### Workflow Example

_Note: the following Lerna commands would typically run on your CI/CD pipeline._

| Event                                                      | Branch         | Lerna Command                                                 | lib_a         | lib_b         | lib_c         | website        |
|:-----------------------------------------------------------|:---------------|:--------------------------------------------------------------|:--------------|:--------------|:--------------|:---------------|
| Start of 1<sup>st</sup> cycle <sup>1</sup>                 | integration    | lerna publish --yes prerelease                                | 1.0.0-alpha.1 | 1.0.0-alpha.1 | 1.0.0-alpha.1 | 1.0.0-alpha.1  |
| Made changes to `lib_a` <sup>2</sup>                       | integration    | lerna publish --yes prerelease                                | 1.0.0-alpha.2 | 1.0.0-alpha.1 | 1.0.0-alpha.1 | 1.0.0-alpha.2  |
| First beta release <sup>3</sup>                            | release/v1.0.0 | lerna publish --yes --force-publish=* --preid=beta prerelease | 1.0.0-beta.0  | 1.0.0-beta.0  | 1.0.0-beta.0  | 1.0.0-beta.0   |
| First production release <sup>4</sup>                      | master         | lerna publish --yes --force-publish=* major                   | 1.0.0         | 1.0.0         | 1.0.0         | 1.0.0          |
| Start of 2<sup>nd</sup> (and any other) cycle <sup>5</sup> | integration    | lerna publish --yes --force-publish=* --preid=alpha preminor  | 1.1.0-alpha.0 | 1.1.0-alpha.0 | 1.1.0-alpha.0 | 1.1.0-alpha.0  |
| Made changes to `lib_a` and `lib_b` <sup>6</sup>           | integration    | lerna publish --yes prerelease                                | 1.1.0-alpha.1 | 1.1.0-alpha.1 | 1.1.0-alpha.0 | 1.1.0-alpha.1  |
| Applied hot fix on 1.0.0 release <sup>7</sup>              | release/v1.0.0 | lerna publish --yes --force-publish=* --preid=beta prepatch   | 1.0.1-beta.0  | 1.0.1-beta.0  | 1.0.1-beta.0  | 1.0.1-beta.0   |
| Released hot fix <sup>8</sup>                              | master         | lerna publish --yes --force-publish=* patch                   | 1.0.1         | 1.0.1         | 1.0.1         | 1.0.1          |

Notes:

1.  Initial publication of all packages. (Start of 1<sup>st</sup> cycle only.)
2.  Publish changes during current development cycle. `website` has been updated because `lib_a` is one of its dependencies.
3.  The `release/v1.0.0` branch has been cut from the `integration` branch.
4.  The `release/v1.0.0` branch has been merged into the `master` branch.
5.  When starting a new development cycle (after the first), we do a minor bump on all packages.
6.  Publish changes during current development cycle.
7.  The hot fix was made on the `integration` branch and cherry-picked onto the `release/v1.0.0` branch (e.g. `git cherry-pick integration --strategy-option=theirs`)
8.  The `release/v1.0.0` branch has been merged into the `master` branch (e.g. `git merge release/v1.0.0 --strategy-option=theirs --no-edit`)

### Appendix: How To Reproduce

First build the Docker container:

```
cd /path/to/lerna-workflow-example
docker build . -t customcommander/lerna-workflow-example
```

You can run all steps mentioned in this article with:

```
cd /path/to/lerna-workflow-example
./run.sh
```

To simply access the repository and experiment by yourself:

```
docker run -it --rm customcommander/lerna-workflow-example
```

_Since everything runs inside the Docker container, you can experiment at will. To start afresh, just spin another instance of the container._
