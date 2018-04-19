# FileSentry

FileSentry is a gem that scans a designated file for malware using a comprehensive suite of anti-malware engines.
It displays results from each engine as well as a brief summary. FileSentry is powered by the OPSWAT Metadefender Cloud API. To use this gem, you will need to create an account with OPSWAT. Don't worry, it's free to sign up!

## Installation

First, make sure you have the latest version of Ruby installed. FileSentry was developed using Ruby 2.5.0, and might not work with older versions of Ruby.

If you do not have Ruby installed, follow the instructions on this blog post to install rbenv and Ruby 2.5.0:[Setup Ruby On Rails on Ubuntu 16.04 Xenial Xerus](https://gorails.com/setup/ubuntu/16.04).

Only install Ruby and rbenv as specified in the 'Installing Ruby' section. Don't
forget to run

    $ rbenv rehash

 after installing bundler!

To install the gem, enter the following in your terminal of choice:

    $ gem install file_sentry

You can also clone this repo if you want to tweak FileSentry. Read the development section for more info if that floats your boat.

## Usage
If you do not have an OPSWAT account/API key, visit [portal.opswat.com](portal.opswat.com) to sign up. After creating an account, the "home" tab will display your OPSWAT API Key.

After installation, to scan a file for malware enter the following command:

    $ file_sentry RELATIVE_PATH_TO_FILE (Optional)HASH_DIGEST


If this is your first time running the application, you will be prompted to enter your API key.

The RELATIVE_PATH_TO_FILE argument loads the specified file into FileSentry, relative to the current working directory. To enter a file name with spaces, use quotation marks or escape whitespace with a backslash.

The HASH_DIGEST argument is optional. If the gem is ran without the HASH_DIGEST argument, FileSentry will default to MD5.

You can change the API key at any time by running the gem without any command line arguments.

## Development

After checking out the repo, run `bin/setup` to install development dependencies. Then, run `rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/f3mshep/file_sentry. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FileSentry project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/f3mshep/file_sentry/blob/master/CODE_OF_CONDUCT.md).
