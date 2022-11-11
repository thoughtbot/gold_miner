# ⛏ GoldMiner

GoldMiner is a tool for finding interesting\* messages in a Slack channel and
turning that into a blog post for the [thoughtbot blog].

It uses the Slack API to search for messages in a channel, then it groups and
formats them into a markdown blog post.

_\* At this point, "interesting" means "messages that contain a 'TIL' or 'tip'".
This is likely to change in the future._

[thoughtbot blog]: https://github.com/thoughtbot/robots.thoughtbot.com

## Installation

First, clone the repo:

```sh
git clone git@github.com:thoughtbot/gold_miner.git
```

Then, run the setup script:

```sh
bin/setup
```

You'll need a Slack API token. You can get it [on 1Password] (search for "Slack
API Token"). If that doesn't work, ask [someone on the team] for help.

[on 1password]: https://start.1password.com/signin
[someone on the team]: https://thoughtbot.slack.com/apps/A040W2T48BF-gold-miner?tab=more_info

## Usage

To generate a blog post, run the following command:

```sh
exe/gold_miner
```

GoldMiner will search on the #dev channel by default. You can also specify a
different channel:

```sh
# Search on the #design channel
exe/gold_miner design
```

This will output a markdown article. Use that as a basis for opening a [new blog
post PR].

> **Note**
> In the future, GoldMiner [will open] a PR for you.

[new blog post pr]: https://vellum.thoughtbot.com/articles/new
[will open]: https://github.com/thoughtbot/gold_miner/issues/1

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/thoughtbot/gold-miner.
