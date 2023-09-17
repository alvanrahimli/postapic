﻿using System.Security.Claims;
using Postapic.Utils;

namespace Postapic.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int? GetUserId(this ClaimsPrincipal principal, AppConfig appConfig, ILogger logger)
    {
        foreach (var c in principal.Claims)
        {
            logger.LogInformation("Claim: {Type}, {Value}", c.Type, c.Value);
        }
        if (principal.Identity?.IsAuthenticated ?? false)
        {
            logger.LogWarning("User not authenticated");
            return null;
        }
        
        var idStr = principal.Claims.FirstOrDefault(c => c.Type == appConfig.IdClaimName)?.Value;
        if (idStr is null)
        {
            logger.LogWarning("Could not find claim: {ClaimName}", appConfig.IdClaimName);
            return null;
        }

        var ok = int.TryParse(idStr, out var id);
        if (!ok) logger.LogWarning("Could not parse id: {Id}", idStr);
        return ok ? id : null;
    }
}