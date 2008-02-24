require 'test/unit'

class TestPostgresTransaction < Test::Unit::TestCase
    def test_rollback
        dbh = get_dbh
        dbh["AutoCommit"] = false
        sth = dbh.prepare('insert into names (name, age) values (?, ?)')
        sth.execute("Foo", 51)
        dbh.rollback
        assert_equal 1, sth.rows
        sth.finish


        sth = dbh.prepare('select name, age from names where name=?')
        sth.execute("Foo")
        assert !sth.fetch
        sth.finish
    end

    def test_commit
        dbh = get_dbh
        dbh["AutoCommit"] = false
        sth = dbh.prepare('insert into names (name, age) values (?, ?)')
        sth.execute("Foo", 51)
        dbh.commit
        assert_equal 1, sth.rows
        sth.finish
        
        sth = dbh.prepare('select name, age from names where name=?')
        sth.execute("Foo")
        row = sth.fetch
        assert row
        assert_equal "Foo", row[0]
        assert_equal 51, row[1]
        sth.finish
    end

    def get_dbh
        DBI.connect('dbi:Pg:rubytest', 'erikh', 'monkeys')
    end

    def setup
        system "psql rubytest < dump.sql >>sql.log"
    end

    def teardown
        system "psql rubytest < drop_tables.sql >>sql.log"
    end
end

if __FILE__ == $0 then
    require 'test/unit/ui/console/testrunner'
    require 'dbi'
    Test::Unit::UI::Console::TestRunner.run(TestPostgresTransaction)
end
