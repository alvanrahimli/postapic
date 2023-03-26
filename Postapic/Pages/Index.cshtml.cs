using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Postapic.Models;
using Postapic.Utils;

namespace Postapic.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly DataContext _context;
    private readonly IOptions<AppConfig> _appConfig;

    public List<Post> Posts { get; set; } = new();
    public PaginationModel Pagination { get; set; }
    [BindProperty] public int DeletePostId { get; set; }

    public IndexModel(ILogger<IndexModel> logger, DataContext context, IOptions<AppConfig> appConfig)
    {
        _logger = logger;
        _context = context;
        _appConfig = appConfig;
    }

    public async Task OnGetAsync()
    {
        Posts = await _context.Posts.AsNoTracking()
            .Include(p => p.Medias)
            .Include(p => p.User)
            .OrderByDescending(p => p.Timestamp)
            .ToListAsync();
    }

    public async Task<ActionResult> OnPostDeletePostAsync()
    {
        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == DeletePostId);
        if (post == null) return RedirectToPage("/Index");
        if (DateTime.UtcNow.Subtract(post.Timestamp).TotalMinutes > 1) return RedirectToPage("/Index");

        _context.Posts.Remove(post);
        await _context.SaveChangesAsync();
        return RedirectToPage("/Index");
    }

    public class PaginationModel
    {
        public int CurrentPage { get; set; }
    }
}
