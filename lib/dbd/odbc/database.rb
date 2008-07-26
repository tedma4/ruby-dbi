class DBI::DBD::ODBC::Database < DBI::BaseDatabase
    include DBI::DBD::ODBC::Converter

    def disconnect
        @handle.rollback
        @handle.disconnect 
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def ping
        @handle.connected?
    end

    def columns(table)
        cols = []

        stmt = @handle.columns(table)
        stmt.ignorecase = true

        stmt.each_hash do |row|
            info = Hash.new
            cols << info

            info['name']      = row['COLUMN_NAME']
            info['type_name'] = row['TYPE_NAME']
            info['sql_type']  = row['DATA_TYPE']
            info['nullable']  = 
                case row['NULLABLE']
                when 1
                    true
                when 0
                    false
                else
                    nil
                end
            info['precision'] = row['PRECISION']
            info['scale']     = row['SCALE']
        end

        stmt.drop
        cols
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def tables
        stmt = @handle.tables
        stmt.ignorecase = true
        tabs = [] 
        stmt.each_hash {|row|
            tabs << row["TABLE_NAME"]
        }
        stmt.drop
        tabs
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def prepare(statement)
        DBI::DBD::ODBC::Statement.new(@handle.prepare(statement), statement)
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def do(statement, *bindvars)
        bindvars = bindvars.collect{|v| convert(v)}
        @handle.do(statement, *bindvars) 
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def execute(statement, *bindvars)
        bindvars = bindvars.collect{|v| convert(v)}
        stmt = @handle.run(statement, *bindvars) 
        DBI::DBD::ODBC::Statement.new(stmt)
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def []=(attr, value)
        case attr
        when 'AutoCommit'
            @handle.autocommit(value)
        when 'odbc_ignorecase'
            @handle.ignorecase(value)
        else
            if attr =~ /^odbc_/ or attr != /_/
                raise DBI::NotSupportedError, "Option '#{attr}' not supported"
            else # option for some other driver - quitly ignore
                return
            end
        end
        @attr[attr] = value
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def commit
        @handle.commit
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

    def rollback
        @handle.rollback
    rescue DBI::DBD::ODBC::ODBCErr => err
        raise DBI::DatabaseError.new(err.message)
    end

end # class Database