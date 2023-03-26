namespace Postapic.Utils;

public class AppConfig
{
    public const string ConfigName = nameof(AppConfig);

    public string BaseUrl { get; set; } = null!;
    public bool AuthenticateIndex { get; set; } = false;
    public int PageSize { get; set; }
    public MediaConfig MediaConfig { get; set; } = new();
}

public class MediaConfig
{
    public int MaxWidth { get; set; }
    public int MaxHeight { get; set; }
}