using Oracle.ManagedDataAccess.Client;
using System.Text;

namespace JsonParser
{
    internal class DbManager
    {
        private string _connectionString;
        private OracleConnection _connection;

        public DbManager(string connectionString)
        {
            _connectionString = connectionString;
            _connection = new OracleConnection(_connectionString);
            TestConnection(); 
        }

        private void TestConnection()
        {
            try
            {
                _connection.Open();
                Console.WriteLine("Connection successfully established.");

                using (var command = new OracleCommand("SELECT * FROM user_role_privs WHERE granted_role = 'DBA'", _connection))
                {
                    var reader = command.ExecuteReader();
                    if (reader.HasRows)
                    {
                        Console.WriteLine("User has DBA privileges.");
                    }
                    else
                    {
                        Console.WriteLine("User does not have DBA privileges.");
                    }
                }
                Console.WriteLine("User System Privileges:");
                using (var command = new OracleCommand("SELECT privilege FROM user_sys_privs", _connection))
                {
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            Console.WriteLine(reader.GetString(0));
                        }
                    }
                }

                Console.WriteLine("User Object Privileges:");
                using (var command = new OracleCommand("SELECT privilege, table_name FROM user_tab_privs", _connection))
                {
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            Console.WriteLine($"{reader.GetString(0)} on {reader.GetString(1)}");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Connection error: {ex.Message}");
            }
            finally
            {
                if (_connection.State == System.Data.ConnectionState.Open)
                {
                    _connection.Close();
                }
            }
        }

        public void OpenConnection()
        {
            if (_connection.State == System.Data.ConnectionState.Closed)
            {
                _connection.Open();
            }
        }

        public void CloseConnection()
        {
            if (_connection.State == System.Data.ConnectionState.Open)
            {
                _connection.Close();
            }
        }

        public string ExecuteSelectQuery(string sql)
        {
            Console.WriteLine(sql);

            try
            {
                OpenConnection();
                using (var command = new OracleCommand(sql, _connection))
                {
                    using (var reader = command.ExecuteReader())
                    {
                        var results = new List<Dictionary<string, object>>();

                        while (reader.Read())
                        {
                            var row = new Dictionary<string, object>();
                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                row[reader.GetName(i)] = reader.GetValue(i) ?? "NULL";
                            }
                            results.Add(row);
                        }

                        return FormatResultsAsTable(results);
                    }
                }
            }
            catch (Exception ex)
            {
                return("Select query error: " + ex.Message);
            }
            finally
            {
                CloseConnection();
            }
        }

        public string ExecuteDmlQuery(string sql)
        {
            Console.WriteLine(sql);

            try
            {
                OpenConnection();
                using (var command = new OracleCommand(sql, _connection))
                {
                    command.ExecuteNonQuery();
                    return "DML query executed successfully";
                }
            }
            catch (Exception ex)
            {
                return "DML query execution error: " + ex.Message;
            }
            finally
            {
                CloseConnection();
            }
        }

        public string ExecuteDdlQuery(string sql)
        {
            Console.WriteLine(sql);

            try
            {
                OpenConnection();
                using (var command = new OracleCommand(sql, _connection))
                {
                    int affectedLinesNumber = command.ExecuteNonQuery();
                    return $"DDL query executed successfully\n {affectedLinesNumber} lines affected";
                }
            }
            catch (Exception ex)
            {
                return("DDL query execution error: " + ex.Message);
            }
            finally
            {
                CloseConnection();
            }
        }

        public string FormatResultsAsTable(List<Dictionary<string, object>> results)
        {
            if (results == null || results.Count == 0)
            {
                return "No rows selected.";
            }

            var output = new StringBuilder();
            var columnWidths = new Dictionary<string, int>();
            var columns = results.First().Keys.ToList();

            foreach (var column in columns)
            {
                columnWidths[column] = column.Length; 
                foreach (var row in results)
                {
                    int valueLength = row[column]?.ToString().Length ?? 4; 
                    columnWidths[column] = Math.Max(columnWidths[column], valueLength);
                }
            }

            string separator = "+" + string.Join("+", columns.Select(c => new string('-', columnWidths[c] + 2))) + "+";

            output.AppendLine(separator);
            output.AppendLine("| " + string.Join(" | ", columns.Select(c => c.PadRight(columnWidths[c]))) + " |");
            output.AppendLine(separator);

            foreach (var row in results)
            {
                output.AppendLine("| " + string.Join(" | ", columns.Select(c => row[c]?.ToString().PadRight(columnWidths[c]) ?? "NULL")) + " |");
            }
            output.AppendLine(separator);

            return output.ToString();
        }
    }
}
