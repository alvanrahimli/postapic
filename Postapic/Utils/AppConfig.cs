namespace Postapic.Utils;

public class AppConfig
{
    public const string ConfigName = nameof(AppConfig);

    public string BaseUrl { get; set; } = null!;
    public bool AuthenticateIndex { get; set; } = false;
    public int PageSize { get; set; }
}