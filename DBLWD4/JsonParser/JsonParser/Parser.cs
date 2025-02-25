using Newtonsoft.Json.Linq;
using System.Data;
using System.Text;

namespace JsonParser
{
    internal class Parser
    {
        DbManager _dbManager;
        string _source = string.Empty;
        string _query = string.Empty;
        JObject _json;

        public Parser(DbManager dbManager)
            => _dbManager = dbManager;  
        public string Parse(string sourcePath)
        {
            _source = File.ReadAllText(sourcePath);
            _json = JObject.Parse(_source);
            switch (_json["queryType"].ToString())
            {
                case "SELECT":
                    _query = createSelectQuery(_json);
                    string response =  _dbManager.ExecuteSelectQuery(_query);
                    break;

                case "CREATE TABLE":
                    _query = createCreateTableQuery();
                    break;

                case "DROP TABLE":
                    _query = createDropTableQuery();
                    break;

                case "INSERT":
                    _query = createInsertQuery();
                    break;

                case "UPDATE":
                    _query = createUpdateQuery();
                    break;

                case "DELETE":
                    _query = createDeleteQuery();
                    break;

                default:
                    return "Wrong promt file format!";
            }
        }

        private string BuildWhereClause(JObject whereJson)
        {
            var whereClauses = new List<string>();
            var conditions = whereJson["conditions"].ToObject<List<JObject>>();

            foreach (var condition in conditions)
            {
                if (condition["operator"] != null)
                {
                    var subquery = (JObject)condition["subquery"]!;
                    var subqueryString = createSelectQuery(subquery);
                    whereClauses.Add($"{condition["operator"]} ({subqueryString})");
                }
                else
                {
                    var clause = $"{condition["column"]} {condition["operator"]} {condition["value"]}";
                    if (condition["logicalOperator"] != null)
                    {
                        clause = $"{condition["logicalOperator"]} {clause}";
                    }
                    whereClauses.Add(clause);
                }
            }

            return string.Join(" ", whereClauses);
        }
        private string createCreateTableQuery()
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("CREATE TABLE ");

            var tableName = _json["table"].ToString();
            queryBuilder.Append(tableName + " (");

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
            queryBuilder.Append(string.Join(", ", columnDefinitions));

            if (_json["constraints"] != null)
            {
                queryBuilder.Append(",");
                var constraints = _json["constraints"].ToObject<List<string>>();
                queryBuilder.Append(string.Join(", ", constraints));
            }

            queryBuilder.Append(");");


            if (_json["primaryKey"] != null)
            {
                queryBuilder.AppendLine();
                queryBuilder.Append($"CREATE SEQUENCE seq_{tableName}_{_json["primaryKey"].ToString()} START WITH 1 INCREMENT BY 1;");

                queryBuilder.AppendLine();
                queryBuilder.Append(
                    $"CREATE TRIGGER {tableName}_pk_trigger " +
                    $"BEFORE INSERT ON {tableName} " +
                    $"FOR EACH ROW " +
                    $"BEGIN " +
                    $"SET NEW.{_json["primaryKey"].ToString()} = NEXTVAL(seq_{tableName}_{_json["primaryKey"].ToString()});" +
                    $"END;");
            }

            return queryBuilder.ToString();
        }
        private string createDropTableQuery()
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("DROP TABLE ");

            var tableName = _json["table"].ToString();
            queryBuilder.Append(tableName);

            if (_json["removeConstraints"] != null && (bool)_json["removeConstraints"])
            {
                queryBuilder.Append(" CASCADE CONSTRAINTS");
            }

            queryBuilder.Append(";");

            if (_json["removeTrigger"] != null && (bool)_json["removeTrigger"])
            {
                var primaryKeyColumn = _json["primaryKey"].ToString();

                queryBuilder.AppendLine();
                queryBuilder.Append($"DROP SEQUENCE IF EXISTS seq_{tableName}_{primaryKeyColumn};");

                queryBuilder.AppendLine();
                queryBuilder.Append($"DROP TRIGGER IF EXISTS {tableName}_pk_trigger;");

            }

            return queryBuilder.ToString();
        }

        private string createDeleteQuery()
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("DELETE FROM ");

            var tables = _json["tables"].ToObject<List<JObject>>();
            queryBuilder.Append(tables[0]["tableName"]); 

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

            var tables = _json["tables"].ToObject<List<JObject>>();
            queryBuilder.Append(tables[0]["tableName"]);

            var columns = _json["columns"].ToObject<List<string>>();
            queryBuilder.Append(" (" + string.Join(", ", columns) + ")");

            var values = _json["values"].ToObject<List<object>>();
            queryBuilder.Append(" VALUES (" + string.Join(", ", values) + ")");

            return queryBuilder.ToString();
        }
        private string createUpdateQuery()
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("UPDATE ");

            var tables = _json["tables"].ToObject<List<JObject>>();
            queryBuilder.Append(tables[0]["tableName"]); 

            queryBuilder.Append(" SET ");
            var updates = _json["updates"].ToObject<List<JObject>>();
            var setClauses = new List<string>();
            foreach (var update in updates)
            {
                setClauses.Add($"{update["column"]} = {update["value"]}");
            }
            queryBuilder.Append(string.Join(", ", setClauses));

            if (_json["where"] != null)
            {
                queryBuilder.Append(" WHERE " + BuildWhereClause((JObject)_json["where"]));
            }

            return queryBuilder.ToString();
        }
        private string createSelectQuery(JObject whereJson)
        {
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("SELECT ");

            var columns = _json["columns"].ToObject<List<string>>();
            queryBuilder.Append(string.Join(", ", columns));
            queryBuilder.AppendLine();

            var tables = _json["tables"].ToObject<List<JObject>>();
            queryBuilder.Append(" FROM " + string.Join(", ", tables.Select(t => $"{t["tableName"]} AS {t["alias"]}")));
            queryBuilder.AppendLine();

            if (_json["joins"] != null)
            {
                foreach (var join in _json["joins"])
                {
                    queryBuilder.Append($" {join["type"]} {join["tableName"]} AS {join["alias"]} ON {join["on"]}");
                }
            }
            queryBuilder.AppendLine();

            if (_json["where"] != null)
            {
                queryBuilder.Append(" WHERE " + BuildWhereClause((JObject)_json["where"]));
            }

            if (_json["groupBy"] != null)
            {
                var groupByColumns = _json["groupBy"].ToObject<List<string>>();
                queryBuilder.Append(" GROUP BY " + string.Join(", ", groupByColumns));
            }

            if (_json["having"] != null)
            {
                var havingConditions = _json["having"]["conditions"].ToObject<List<JObject>>();
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

            if (_json["orderBy"] != null)
            {
                var orderByColumns = _json["orderBy"].ToObject<List<JObject>>();
                var orderByClauses = new List<string>();
                foreach (var order in orderByColumns)
                {
                    orderByClauses.Add($"{order["column"]} {order["direction"]}");
                }
                queryBuilder.Append(" ORDER BY " + string.Join(", ", orderByClauses));
            }

            return queryBuilder.ToString();
        }
    }
}
