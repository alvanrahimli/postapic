using System.Security.Claims;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Postapic.Models;
using Postapic.Models.Enums;

namespace Postapic.Pages;

public class PostPage : PageModel
{
    private readonly DataContext _context;
    private readonly IWebHostEnvironment _environment;

    public PostPage(DataContext context, IWebHostEnvironment environment)
    {
        _context = context;
        _environment = environment;
    }

    public async Task OnPostCreateDraftAsync()
    {
        if (Request.Form.Files.Count == 0) return;
        
        // Image processing
        List<Media> medias = new();
        foreach (var formFile in Request.Form.Files)
        {
            var filePath = Path.Combine(_environment.ContentRootPath, "Uploads", formFile.FileName);
            await using var fileStream = new FileStream(filePath, FileMode.Create);
            await formFile.CopyToAsync(fileStream);
            medias.Add(new Media
            {
                Key = Path.Combine("Uploads", formFile.FileName),
                Height = 15,
                Width = 15,
                Type = MediaType.Image
            });
        }

        await _context.Posts.AddAsync(new Post
        {
            Medias = medias,
            Permalink = "testing",
            Timestamp = DateTime.UtcNow,
            Title = "Some title",
            UserId = int.Parse(User.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)!.Value)
        });
        await _context.SaveChangesAsync();
    }
}