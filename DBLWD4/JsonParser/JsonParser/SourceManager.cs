namespace JsonParser
{
    internal static class SourceManager
    {
        static string _sourceDirectory = "D:\\uni\\DbOracleLabs\\DBLWD4\\promts";
        static string _format = "*.json";
        static Parser _parser = new();
        public static async Task StartUp()
        {
            while (true)
            {
                string[] promtFilePathes =
                    Directory.GetFiles(_sourceDirectory, _format);
                Console.WriteLine("Select a file");
                Console.WriteLine("0. Exit program");
                for (int i = 1; i < promtFilePathes.Length + 1; ++i)
                {
                    Console.WriteLine($"{i}. {Path.GetFileName(promtFilePathes[i - 1])}");
                }

                try
                {
                    uint selectedIndex = uint.Parse(Console.ReadLine());
                    if (selectedIndex == 0)
                        break;

                    string selectedPromt = promtFilePathes[selectedIndex - 1];
                    string response = await _parser.Parse(selectedPromt);
                    
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
