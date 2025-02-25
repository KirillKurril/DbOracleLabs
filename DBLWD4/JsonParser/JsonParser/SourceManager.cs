namespace JsonParser
{
    internal class SourceManager
    {

        public static string PrintFileList(
            string _sourceDirectory, 
            string _format)
        {
                string[] promtFilePathes = Directory.GetFiles(_sourceDirectory, _format);
                Console.WriteLine("Select a file");
                Console.WriteLine("0. Exit program");
                for (int i = 1; i < promtFilePathes.Length + 1; ++i)
                {
                    Console.WriteLine($"{i}. {Path.GetFileName(promtFilePathes[i - 1])}");
                }

                uint selectedIndex = uint.Parse(Console.ReadLine());
                if (selectedIndex == 0)
                    Environment.Exit(0);

            return promtFilePathes[selectedIndex - 1];
        }
    }
}
