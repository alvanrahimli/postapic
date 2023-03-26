using Microsoft.EntityFrameworkCore;
using Postapic.Models;

namespace Postapic.Utils;

public static class Initialization
{
    public static async Task InitializeAdmin(IServiceProvider services)
    {
        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<DataContext>();
        
        var adminExists = await db.Users.AnyAsync(u => u.IsAdmin);
        if (adminExists) return;

        var adminUsername = Environment.GetEnvironmentVariable("ADMIN_USERNAME");
        var adminPassword = Environment.GetEnvironmentVariable("ADMIN_PASSWORD");
        
        if (string.IsNullOrEmpty(adminUsername))
            throw new InitializationException("Environment variable ADMIN_USERNAME is not defined");
        if (string.IsNullOrEmpty(adminPassword))
            throw new InitializationException("Environment variable ADMIN_PASSWORD is not defined");
        
        var firstAdmin = await db.Users.FirstOrDefaultAsync(u => u.Username == adminUsername);
        if (firstAdmin is null)
        {
            firstAdmin = new AppUser
            {
                Username = adminUsername,
                PasswordHash = CryptoHelpers.GeneratePwdHash(adminPassword),
                IsAdmin = true
            };
            await db.Users.AddAsync(firstAdmin);
            if (await db.SaveChangesAsync() == 0)
                throw new InitializationException("Could not create initial admin");
        }
    }
}