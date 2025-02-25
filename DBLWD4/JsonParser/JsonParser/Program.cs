namespace JsonParser
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            string connectionString = "User Id=C##ADMIN_USER;Password=1111;Data Source=localhost:1521/xe;";
            string _sourceDirectory = "D:\\uni\\DbOracleLabs\\DBLWD4\\promts";
            string _format = "*.json";
            DbManager dbManager = new(connectionString);
            Parser _parser = new(dbManager);


            while (true)
            {
                try
                {
                    string selectedPromt = SourceManager.PrintFileList(
                        _sourceDirectory,
                        _format);

                    string response = _parser.Parse(selectedPromt);
                    Console.WriteLine(response);
                }
                catch
                {
                    Console.WriteLine("Incorrect input, try again");
                    continue;
                }
            }
        }
    }
}
