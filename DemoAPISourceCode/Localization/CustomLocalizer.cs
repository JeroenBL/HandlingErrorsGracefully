namespace ErrorhandlingDemoAPI.Localization
{
    public class CustomLocalizer : ICustomLocalizer
    {
        private readonly Dictionary<string, Dictionary<string, string>> _translations;

        public CustomLocalizer()
        {
            _translations = new Dictionary<string, Dictionary<string, string>>()
            {
                { "en", new Dictionary<string, string>
                    {
                        { "UserNotFoundDetail", "A user with id {0} could not be found. Make sure the Id exists and try again" },
                        { "NotFound", "Not Found" }
                    }
                },
                { "de", new Dictionary<string, string>
                    {
                        { "UserNotFoundDetail", "Ein Benutzer mit der ID {0} konnte nicht gefunden werden. Stellen Sie sicher, dass die ID existiert und versuchen Sie es erneut" },
                        { "NotFound", "Nicht gefunden" }
                    }
                }
            };
        }

        public string GetString(string key, string culture = "de")
        {
            if (_translations.ContainsKey(culture) && _translations[culture].ContainsKey(key))
            {
                return _translations[culture][key];
            }

            // Fallback to English if the culture or key is not found
            return _translations["de"].GetValueOrDefault(key, key);
        }
    }

    public interface ICustomLocalizer
    {
        string GetString(string key, string culture = "en");
    }
}