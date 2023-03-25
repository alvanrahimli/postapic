using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Postapic.Models;
using Postapic.Utils;

namespace Postapic.Pages;

public class Login : PageModel
{
    private readonly DataContext _context;

    [BindProperty] public LoginModel LoginModel { get; set; }

    public string UiMessage { get; set; } = string.Empty;

    public Login(DataContext context)
    {
        _context = context;
    }
    
    public void OnGet()
    {
        
    }

    public async Task<ActionResult> OnPostAsync()
    {
        var sameNameUsers = await _context.Users.AsNoTracking()
            .Where(u => u.Username == LoginModel.Username).ToListAsync();

        var inputHash = CryptoHelpers.GeneratePwdHash(LoginModel.Password);
        var user = sameNameUsers.FirstOrDefault(u => u.PasswordHash == inputHash);
        if (user == null)
        {
            UiMessage = "Invalid login attempt.";
            return Page();
        }
        
        var claims = new List<Claim>
        {
            new(ClaimTypes.Name, user.Username),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Role, user.IsAdmin ? "Admin" : "User")
        };
        var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(claimsIdentity), new AuthenticationProperties()
                { IsPersistent = true });

        return RedirectToPage("/Index");
    }
}

public class LoginModel
{
    public string Username { get; set; } = null!;
    public string Password { get; set; } = null!;
}