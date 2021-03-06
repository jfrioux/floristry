# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require 'form_task_helper'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../dummy/rails_app/config/environment', __FILE__)
Dir[File.expand_path("spec/stubs/**/*.rb")].each {|f| require f}
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'rspec/active_model/mocks'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Make sure it looks for migrations in the dummy app instead of the engine
ActiveRecord::Migrator.migrations_paths = 'dummy/rails_app/db/migrate'
# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

RSpec.configure do |c|
  c.include FormTaskHelper
end

# Reopen Floristry::Workflow, assigning a default value to `@current_nids`
# and adding an accessor. This allows to have the exact `@current_nids` we
# need in views spec (which procedure(s) is active, in the past, etc)
# and remove the dependency on a running flack instance during spec runs.
Floristry::Workflow.class_eval do
  alias_method :original_initialize, :initialize
  def initialize(id, trail)

    original_initialize(id, trail)
    @current_nids = ["0_1"]
  end

  def current_nids= nids

    @current_nids = nids
  end
end