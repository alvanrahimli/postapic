using Microsoft.AspNetCore.Mvc.RazorPages;
using Postapic.Models;

namespace Postapic.Pages;

public class PostPage : PageModel
{
    private readonly DataContext _context;
    
    public PostPage(DataContext context)
    {
        _context = context;
    }
    
    public void OnGet()
    {
        
    }
}