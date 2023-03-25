using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Postapic.Models;

namespace Postapic.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly DataContext _context;

    public List<Post> Posts { get; set; } = new();

    public IndexModel(ILogger<IndexModel> logger, DataContext context)
    {
        _logger = logger;
        _context = context;
    }

    public async Task OnGetAsync()
    {
        Posts = await _context.Posts.AsNoTracking()
            .Include(p => p.Medias)
            .Include(p => p.User)
            .OrderByDescending(p => p.Timestamp)
            .ToListAsync();
    }
}
