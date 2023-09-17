using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Postapic.Extensions;
using Postapic.Models;
using Postapic.Utils;
using Upload.Core;

namespace Postapic.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly DataContext _context;
    private readonly StorageManager _storageManager;
    private readonly IOptions<AppConfig> _appConfig;

    public List<Post> Posts { get; set; } = new();
    
    public PaginationModel Pagination { get; set; } = new();
    [FromQuery(Name = "page")] 
    public int Page { get; set; }
    
    [BindProperty] public int DeletePostId { get; set; }

    public IndexModel(ILogger<IndexModel> logger, DataContext context,
        StorageManager storageManager,
        IOptions<AppConfig> appConfig)
    {
        _logger = logger;
        _context = context;
        _storageManager = storageManager;
        _appConfig = appConfig;
    }

    public async Task OnGetAsync()
    {
        if (Page <= 0) Page = 1;
        
        var offset = (Page - 1) * _appConfig.Value.PageSize;
        Posts = await _context.Posts.AsNoTracking()
            .Where(p => !p.Draft)
            .Include(p => p.Medias)
            .Include(p => p.User)
            .OrderByDescending(p => p.Timestamp)
            .Skip(offset).Take(_appConfig.Value.PageSize)
            .ToListAsync();
        
        var count = await _context.Posts.Where(p => !p.Draft).CountAsync();
        var lastPage = (int)Math.Ceiling((float)count / _appConfig.Value.PageSize);
        
        Pagination = new PaginationModel
        {
            ShowBackwardControls = Page > 1,
            FirstPage = 1,
            PreviousPage = Page == 1 ? 1 : Page - 1,
            CurrentPage = Page,
            NextPage = Page == lastPage ? lastPage : Page + 1,
            LastPage = lastPage,
            ShowForwardControls = Page < lastPage
        };
    }

    public async Task<ActionResult> OnPostDeletePostAsync()
    {
        var userId = User.GetUserId(_appConfig.Value);
        if (userId is null) 
            return Page();
        
        var post = await _context.Posts.Include(p => p.Medias).FirstOrDefaultAsync(p => p.Id == DeletePostId);
        if (post == null) 
            return RedirectToPage("/Index");
        
        if (post.UserId != (int)userId)
            return RedirectToPage("/Index");
        
        if (DateTime.UtcNow.Subtract(post.Timestamp).TotalMinutes > 1) return RedirectToPage("/Index");

        _context.Posts.Remove(post);
        foreach (var postMedia in post.Medias)
        {
            // I'll just do replace and get over it
            var fileRef = await _storageManager.GetFile("primary", postMedia.Key.Replace("/media", ""));
            if (fileRef is null) continue;

            var ok = await fileRef.Delete();
            if (!ok)
            {
                _logger.LogWarning("Post is being deleted, but media {Key} could not be deleted!", postMedia.Key);
            }
        }
        await _context.SaveChangesAsync();
        return RedirectToPage("/Index");
    }

    public class PaginationModel
    {
        public bool ShowBackwardControls { get; set; }
        public int FirstPage { get; set; }
        public int PreviousPage { get; set; }
        public int CurrentPage { get; set; }
        public int NextPage { get; set; }
        public int LastPage { get; set; }
        public bool ShowForwardControls { get; set; }
    }
}
