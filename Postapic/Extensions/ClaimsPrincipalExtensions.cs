using System.Security.Claims;
using Postapic.Utils;

namespace Postapic.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int? GetUserId(this ClaimsPrincipal principal, AppConfig appConfig, ILogger logger)
    {
        var claimName = string.IsNullOrEmpty(appConfig.IdClaimName) 
            ? ClaimTypes.NameIdentifier 
            : appConfig.IdClaimName;

        // TODO: This returns false, even if we have correct claim for identity
        // if (principal.Identity?.IsAuthenticated ?? false)
        // {
        //     logger.LogWarning("User not authenticated");
        //     return null;
        // }
        
        var idStr = principal.Claims.FirstOrDefault(c => c.Type == claimName)?.Value;
        if (idStr is null)
        {
            logger.LogWarning("Could not find claim: {ClaimName}", claimName);
            return null;
        }

        if (int.TryParse(idStr, out var id))
            return id;
        
        logger.LogWarning("Could not parse id: {Id}", idStr);
        return null;
    }
}