using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Postapic.Models;
using Postapic.Utils;

namespace Postapic.Pages.Settings;

public class SettingsPage : PageModel
{
    private readonly DataContext _context;
    public List<AppUser> UserList { get; set; } = new();
    
    [BindProperty] public CreateUserModel UserModel { get; set; }

    [BindProperty] public int DeleteUserId { get; set; }
    [BindProperty] public int ToggleAdminUserId { get; set; }

    public string UiMessage { get; set; } = string.Empty;

    public SettingsPage(DataContext context)
    {
        _context = context;
    }
    
    public async Task OnGetAsync()
    {
        UserList = await _context.Users.AsNoTracking().ToListAsync();
    }

    public async Task<ActionResult> OnPostCreateUserAsync()
    {
        UiMessage = "";
        
        var sameName = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == UserModel.Username);
        if (sameName is not null)
        {
            UiMessage = "Could not create new user. Duplicate username";
            UserList = await _context.Users.AsNoTracking().ToListAsync();
            return Page();
        }
        
        var appUser = new AppUser
        {
            Username = UserModel.Username,
            PasswordHash = CryptoHelpers.GeneratePwdHash(UserModel.Password),
            IsAdmin = UserModel.IsAdmin
        };
        await _context.Users.AddAsync(appUser);
        if (await _context.SaveChangesAsync() == 0)
        {
            UiMessage = "Could not create user";
        }

        return RedirectToPage("/Settings/Index");
    }

    public async Task<ActionResult> OnPostDeleteUserAsync()
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == DeleteUserId);
        if (user is null) return RedirectToPage("/Settings/Index");

        _context.Users.Remove(user);
        if (await _context.SaveChangesAsync() == 0)
        {
            UiMessage = "Could not delete user";
        }

        return RedirectToPage("/Settings/Index");
    }

    public async Task<ActionResult> OnPostToggleAdminAsync()
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == ToggleAdminUserId);
        if (user is null) return RedirectToPage("/Settings/Index");

        user.IsAdmin = !user.IsAdmin;
        if (await _context.SaveChangesAsync() > 0)
        {
            return RedirectToPage("/Settings/Index");
        }
        
        ViewData["toggle-admin-msg"] = user.IsAdmin ? "Could not make user admin" : "Could not remove admin role";
        UserList = await _context.Users.AsNoTracking().ToListAsync();
        return Page();
    }

    public class CreateUserModel
    {
        public string Username { get; set; } = null!;
        public string Password { get; set; } = null!;
        public bool IsAdmin { get; set; }
    }
}