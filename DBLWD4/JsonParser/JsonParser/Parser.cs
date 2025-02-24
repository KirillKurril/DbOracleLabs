using Newtonsoft.Json.Linq;

namespace JsonParser
{
    internal class Parser
    {
        string _source = string.Empty;
        string _query = string.Empty;
        JObject _json;
        public async Task<string> Parse(string sourcePath)
        {
            _source = File.ReadAllText(sourcePath);
            _json = JObject.Parse(_source);
            switch (_json["queryType"].ToString())
            {
                case "SELECT":
                    createSelectQuery();
                    break;

                case "CREATE TABLE":
                    createCreateTableQuery();
                    break;

                case "DROP TABLE":
                    createDropTableQuery();
                    break;

                case "INSERT":
                    createInsertQuery();
                    break;

                case "UPDATE":
                    createUpdateQuery();
                    break;

                case "DELETE":
                    createDeleteQuery();
                    break;

                default:
                    return "Wrong promt file format!";
            }
            return await performRequest();
        }

        private string createCreateTableQuery()
        {
            throw new NotImplementedException();
        }
        private string createDropTableQuery()
        {
            throw new NotImplementedException();
        }

        private string createDeleteQuery()
        {
            throw new NotImplementedException();
        }
        private string createInsertQuery()
        {
            throw new NotImplementedException();
        }
        private string createUpdateQuery()
        {
            throw new NotImplementedException();
        }
        private string createSelectQuery()
        {
            throw new NotImplementedException();
        }
        private async Task<string> performRequest()
        {
            throw new NotImplementedException();
        }
    }
}
