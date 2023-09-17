using System.Security.Claims;

namespace Postapic.Utils;

public class AppConfig
{
    public const string ConfigName = nameof(AppConfig);

    public string BaseUrl { get; set; } = null!;
    public bool AuthenticateIndex { get; set; }
    public int PageSize { get; set; }
    public MediaConfig MediaConfig { get; set; } = new();

    public string IdClaimName { get; set; } = ClaimTypes.NameIdentifier;
    public string AuthenticateWith { get; set; } = "cookie";
}

public class MediaConfig
{
    public int MaxWidth { get; set; }
    public int MaxHeight { get; set; }
}