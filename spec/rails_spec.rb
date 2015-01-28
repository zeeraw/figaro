describe Figaro::Rails do
  before do
    run_simple(<<-CMD)
      rails new example \
        --skip-gemfile \
        --skip-bundle \
        --skip-keeps \
        --skip-sprockets \
        --skip-javascript \
        --skip-test-unit \
        --no-rc \
        --quiet
      CMD
    cd("example")
  end

  describe "initialization" do
    before do
      write_file("config/application.yml", "foo: bar")
    end

    it "loads application.yml" do
      run_simple("rails runner 'puts Figaro.env.foo'")

      assert_partial_output("bar", all_stdout)
    end

    it "happens before database initialization" do
      write_file("config/database.yml", <<-EOF)
development:
  adapter: sqlite3
  database: db/<%= ENV["foo"] %>.sqlite3
EOF

      run_simple("rake db:migrate")

      check_file_presence(["db/bar.sqlite3"], true)
    end

    it "happens before application configuration" do
      insert_into_file_after("config/application.rb", /< Rails::Application$/, <<-EOL)
    config.foo = ENV["foo"]
EOL

      run_simple("rails runner 'puts Rails.application.config.foo'")

      assert_partial_output("bar", all_stdout)
    end

    context "when there is no config/database.yml" do

      before { remove_file("config/database.yml") }

      it "raises error when DATABASE_URL is not specified in application.yml" do
        expect(run_simple("rake db:migrate", false)).to be_nil
      end

      it "allows DATABASE_URL to be specified in application.yml" do
        write_file("config/application.yml", "database_url: sqlite3:db/database-url-test.sqlite3?timeout=5000&pool=5")
        run_simple("rake db:migrate")
        check_file_presence(["db/database-url-test.sqlite3"], true)
        remove_file("db/database-url-test.sqlite3")
      end

    end
  end
end
