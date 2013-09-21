require "helper"
require "rails/generators"
require "generators/acl_permalink_generator"

class AclPermalinkGeneratorTest < Rails::Generators::TestCase

  tests AclPermalinkGenerator
  destination File.expand_path("../../tmp", __FILE__)

  setup :prepare_destination

  test "should generate a migration" do
    begin
      run_generator
      assert_migration "db/migrate/create_acl_permalink_slugs"
    ensure
      FileUtils.rm_rf self.destination_root
    end
  end
end
