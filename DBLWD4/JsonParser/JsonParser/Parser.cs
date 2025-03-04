using Newtonsoft.Json.Linq;
using System.Data;
using System.Text;

namespace JsonParser
{
    internal class Parser
    {
        DbManager _dbManager;
        string _source = string.Empty;
        JObject _json;

        public Parser(DbManager dbManager)
            => _dbManager = dbManager;  
        public string Parse(string sourcePath)
        {
            _source = File.ReadAllText(sourcePath);
            _json = JObject.Parse(_source);
            string response = string.Empty;

            switch (_json["queryType"].ToString())
            {
                case "SELECT":
                    var selectQuery = createSelectQuery(_json);
                    LogQuery(selectQuery);
                    response =  _dbManager.ExecuteSelectQuery(selectQuery);
                    break;

                case "CREATE TABLE":
                    var createTableQuery = createCreateTableQuery();
                    LogQuery(createTableQuery);
                    response = _dbManager.ExecuteDdlQuery(createTableQuery);
                    break;

                case "DROP TABLE":
                    var dropTableQuery = createDropTableQuery();
                    LogQuery(dropTableQuery);
                    response = _dbManager.ExecuteDdlQuery(dropTableQuery);
                    break;

                case "INSERT":
                    var insertQuery = createInsertQuery();
                    LogQuery(insertQuery);
                    response = _dbManager.ExecuteDmlQuery(insertQuery);
                    break;

                case "UPDATE":
                    var updateQuery = createUpdateQuery();
                    LogQuery(updateQuery);
                    response = _dbManager.ExecuteDmlQuery(updateQuery);
                    break;

                case "DELETE":
                    var deleteQuery = createDeleteQuery();
                    LogQuery(deleteQuery);
                    response = _dbManager.ExecuteDmlQuery(deleteQuery);
                    break;

                default:
                    response = "Wrong promt file format!";
                    break;
            }
            return response;
        }

        private string BuildWhereClause(JObject whereJson)
        {
            var whereClauses = new List<string>();
            var conditions = whereJson["conditions"].ToObject<List<JObject>>();

            foreach (var condition in conditions)
            {
                if (condition["logicalOperator"] != null)
                {
                    whereClauses.Add($"{condition["logicalOperator"]} ");
                }

                if (condition["operator"].ToString().Contains("EXIST") || condition["operator"].ToString().Contains("IN"))
                {
                    var subquery = (JObject)condition["subquery"]!;
                    var subqueryString = createSelectQuery(subquery);
                    whereClauses.Add($"{condition["operator"]} ({subqueryString})");
                }
                else
                {
                    string value;
                    var tokenValue = condition["value"];

                    if (tokenValue.Type == JTokenType.String)
                    {
                        string strValue = tokenValue.ToString();
                        if (DateTime.TryParse(strValue, out _))
                            value = $"'{strValue}'";
                        else
                            value = $"'{strValue}'"; 
                    }
                    else
                    {
                        value = condition["value"].ToString();
                    }

                    var clause = $"{condition["column"]} {condition["operator"]} {value}";
                    whereClauses.Add(clause);
                }
            }

            return string.Join(" ", whereClauses);
        }
        private List<string> createCreateTableQuery()
        {
            List<string> queries = new();
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("CREATE TABLE ");

            var tableName = _json["table"].ToString();
            queryBuilder.Append(tableName + " (");
            queryBuilder.AppendLine();

            var columns = _json["columns"].ToObject<List<JObject>>();
            var columnDefinitions = new List<string>();

            foreach (var column in columns)
            {
                var columnName = column["name"].ToString();
                var columnType = column["type"].ToString();
                var columnDefinition = $"{columnName} {columnType}";

                if (column["constraints"] != null)
                {
                    var constraints = column["constraints"].ToObject<List<string>>();
                    columnDefinition += " " + string.Join(" ", constraints);
                }

                columnDefinitions.Add(columnDefinition);
            }
            queryBuilder.Append(string.Join(", \n", columnDefinitions));


            if (_json["constraints"] != null)
            {
                queryBuilder.Append(", \n");
                var constraints = _json["constraints"].ToObject<List<string>>();
                queryBuilder.Append(string.Join(", \n", constraints));
            }
            queryBuilder.Append(")");
            queries.Add(queryBuilder.ToString());
            queryBuilder.Clear();


            if (_json["primaryKey"] != null)
            {
                queryBuilder.Append($"CREATE SEQUENCE seq_{tableName}_{_json["primaryKey"].ToString()} START WITH 1 INCREMENT BY 1");

                queries.Add(queryBuilder.ToString());
                queryBuilder.Clear();

                queryBuilder.Append(
                    $"CREATE OR REPLACE TRIGGER {tableName}_pk_trigger \n" +
                    $"BEFORE INSERT ON {tableName} \n" +
                    $"FOR EACH ROW \n" +
                    $"BEGIN \n" +
                    $"    :NEW.{_json["primaryKey"].ToString()} := seq_{tableName}_{_json["primaryKey"].ToString()}.NEXTVAL;\n" +
                    $"END;");

                queries.Add(queryBuilder.ToString());
                queryBuilder.Clear();
            }

            return queries;
        }
        private List<string> createDropTableQuery()
        {
            List<string> queries = new();
            var queryBuilder = new StringBuilder();

            queryBuilder.Append("DROP TABLE ");

            var tableName = _json["table"].ToString();
            queryBuilder.Append(tableName);

            if (_json["removeConstraints"] != null && (bool)_json["removeConstraints"])
            {
                queryBuilder.Append(" CASCADE CONSTRAINTS");
            }

            queries.Add(queryBuilder.ToString());
            queryBuilder.Clear();

            if (_json["removeTrigger"] != null && (bool)_json["removeTrigger"])
            {
                var primaryKeyColumn = _json["primaryKey"].ToString();

                queryBuilder.Append($"DROP SEQUENCE seq_{tableName}_{primaryKeyColumn}\n");

                queries.Add(queryBuilder.ToString());
                queryBuilder.Clear();
            }

            return queries;
        }

        private string createDeleteQuery()
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("DELETE FROM ");

            var table = _json["table"].ToString();
            queryBuilder.Append(table);
            queryBuilder.AppendLine();

            if (_json["where"] != null)
            {
                queryBuilder.Append(" WHERE " + BuildWhereClause((JObject)_json["where"]));
            }
            return queryBuilder.ToString();
        }
        private string createInsertQuery()
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("INSERT INTO ");

            var table = _json["table"].ToString();
            queryBuilder.Append(table);

            var columns = _json["columns"].ToObject<List<string>>();
            queryBuilder.Append(" (" + string.Join(", ", columns) + ")");
            queryBuilder.AppendLine();

            var values = _json["values"].ToObject<List<object>>();
            var formattedValues = new List<string>();


            foreach (var value in values)
            {
                if (value is string strValue)
                {
                    if (DateTime.TryParse(strValue, out _))
                        formattedValues.Add($"'{strValue}'"); 
                    else
                        formattedValues.Add($"'{strValue}'"); 
                }
                else
                {
                    formattedValues.Add(value.ToString()); 
                }
            }

            queryBuilder.Append(" VALUES (" + string.Join(", ", formattedValues) + ")");
            queryBuilder.AppendLine();

            return queryBuilder.ToString();
        }
        private string createUpdateQuery()
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("UPDATE ");

            var table = _json["table"].ToString();
            queryBuilder.Append(table);
            queryBuilder.AppendLine();

            queryBuilder.Append(" SET ");
            var setValues = _json["set"].ToObject<Dictionary<string, object>>();
            var setClauses = new List<string>();

            foreach (var kvp in setValues)
            {
                string value;

                if (kvp.Value is string strValue)
                {
                    if (DateTime.TryParse(strValue, out _))
                        value = $"'{strValue}'"; 
                    else
                        value = $"'{strValue}'"; 
                }
                else
                {
                    value = kvp.Value.ToString(); 
                }

                setClauses.Add($"{kvp.Key} = {value}");
            }


            queryBuilder.Append(string.Join(", ", setClauses));
            queryBuilder.AppendLine();


            if (_json["where"] != null)
            {
                queryBuilder.Append(" WHERE " + BuildWhereClause((JObject)_json["where"]));
            }

            return queryBuilder.ToString();
        }
        private string createSelectQuery(JObject json)
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("SELECT ");

            var columns = json["columns"].ToObject<List<string>>();
            queryBuilder.Append(string.Join(", ", columns));
            queryBuilder.AppendLine();

            var tables = json["tables"].ToObject<List<JObject>>();
            queryBuilder.Append(" FROM " + string.Join(", ", tables.Select(t => $"{t["tableName"]} AS {t["alias"]}")));

            if (json["joins"] != null)
            {
                queryBuilder.AppendLine();

                foreach (var join in json["joins"])
                {
                    queryBuilder.Append($" {join["type"]} {join["tableName"]} AS {join["alias"]} ON {join["on"]}");
                }
            }

            if (json["where"] != null)
            {
                queryBuilder.AppendLine();

                queryBuilder.Append(" WHERE " + BuildWhereClause((JObject)json["where"]));
            }

            if (json["groupBy"] != null)
            {
                queryBuilder.AppendLine();

                var groupByColumns = json["groupBy"].ToObject<List<string>>();
                queryBuilder.Append(" GROUP BY " + string.Join(", ", groupByColumns));
            }

            if (json["having"] != null)
            {
                queryBuilder.AppendLine();

                var havingConditions = json["having"]["conditions"].ToObject<List<JObject>>();
                if (havingConditions.Count > 0)
                {
                    queryBuilder.Append(" HAVING ");
                    var havingClauses = new List<string>();
                    foreach (var condition in havingConditions)
                    {
                        var clause = $"{condition["column"]} {condition["operator"]} {condition["value"]}";
                        havingClauses.Add(clause);
                    }
                    queryBuilder.Append(string.Join(" AND ", havingClauses));
                }
            }

            if (json["orderBy"] != null)
            {
                queryBuilder.AppendLine();

                var orderByColumns = json["orderBy"].ToObject<List<JObject>>();
                var orderByClauses = new List<string>();
                foreach (var order in orderByColumns)
                {
                    orderByClauses.Add($"{order["column"]} {order["direction"]}");
                }
                queryBuilder.Append(" ORDER BY " + string.Join(", ", orderByClauses));
            }
            return queryBuilder.ToString();
        }

        private void LogQuery(List<string> queries)
        {
            var path = @"D:\uni\DbOracleLabs\DBLWD4\log.txt";
            File.WriteAllTextAsync(path, string.Join("\n", queries));
        }

        private void LogQuery(string query)
        {
            var path = @"D:\uni\DbOracleLabs\DBLWD4\log.txt";
            File.WriteAllTextAsync(path, query);
        }
    }
}
