using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Postapic.Models;

namespace Postapic.Pages;

public class SinglePost : PageModel
{
    private readonly DataContext _context;
    public Post? Post { get; set; }

    public SinglePost(DataContext context)
    {
        _context = context;
    }
    
    public async Task<ActionResult> OnGet(string idOrPermalink)
    {
        var query = _context.Posts.Include(p => p.Medias).Include(p => p.User);
        var isInt = int.TryParse(idOrPermalink, out var id);
        if (isInt)
        {
            Post = await query.FirstOrDefaultAsync(p => p.Id == id);
        }
        else
        {
            Post = await query.FirstOrDefaultAsync(p => p.Permalink == idOrPermalink);
        }

        if (Post == null) return RedirectToPage("/Error");
        
        return Page();
    }
}