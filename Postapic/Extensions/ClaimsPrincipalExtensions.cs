using System.Security.Claims;
using Microsoft.Extensions.Options;
using Postapic.Utils;

namespace Postapic.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int? GetUserId(this ClaimsPrincipal principal, AppConfig appConfig)
    {
        if (principal.Identity?.IsAuthenticated ?? false)
            return null;
        
        var idStr = principal.Claims.FirstOrDefault(c => c.Type == appConfig.IdClaimName)?.Value;
        if (idStr is null)
            return null;

        var ok = int.TryParse(idStr, out var id);
        return ok ? id : null;
    }
}