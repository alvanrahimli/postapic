using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Postapic.Models;
using Postapic.Models.Enums;
using Upload.Core;

namespace Postapic.Pages;

public class PostPage : PageModel
{
    private readonly DataContext _context;
    private readonly StorageManager _storageManager;

    public PostPage(DataContext context, StorageManager storageManager)
    {
        _context = context;
        _storageManager = storageManager;
    }
    
    [BindProperty] public SubmitPostModel SubmitPostDto { get; set; }
    
    public Post DraftPost { get; set; }

    public async Task<ActionResult> OnPostCreateDraftAsync()
    {
        if (Request.Form.Files.Count == 0) RedirectToPage("/Index");;
        
        List<Media> medias = new();
        foreach (var formFile in Request.Form.Files)
        {
            await using var stream = formFile.OpenReadStream();
            var fileRef = await _storageManager.CreateFile("primary",
                $"{DateTime.UtcNow:yyyy-MM-ddThh-mm-ss}-{Random.Shared.Next(10, 100)}{Path.GetExtension(formFile.FileName)}", stream);
            medias.Add(new Media
            {
                Key = $"media/{fileRef.Key}",
                Height = 15,
                Width = 15,
                Type = MediaType.Image
            });
        }

        var draftPost = new Post
        {
            Medias = medias,
            Permalink = $"DRAFT-{Random.Shared.Next(100, 1000)}",
            Timestamp = DateTime.UtcNow,
            Title = "DRAFT",
            UserId = int.Parse(User.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)!.Value),
            Draft = true
        };
        await _context.Posts.AddAsync(draftPost);
        if (await _context.SaveChangesAsync() == 0)
        {
            return RedirectToPage("/Error");
        }

        DraftPost = draftPost;
        return Page();
    }

    public async Task<ActionResult> OnPostPublishAsync()
    {
        var draft = await _context.Posts.FirstOrDefaultAsync(p => p.Id == SubmitPostDto.DraftId && p.Draft);
        if (draft is null) return RedirectToPage("/Error");

        draft.Title = SubmitPostDto.Title;
        if (!string.IsNullOrEmpty(SubmitPostDto.Permalink?.Trim()))
        {
            var samePermalink = await _context.Posts.FirstOrDefaultAsync(p => p.Permalink == SubmitPostDto.Permalink.Replace(' ', '_'));
            if (samePermalink is null)
            {
                draft.Permalink = SubmitPostDto.Permalink.Replace(' ', '_');
            }
            else
            {
                ViewData["error-msg"] = "Another post with the same permalink exists. Please change and publish again";
                draft.Permalink = string.Empty;
                DraftPost = draft;
                return Page();
            }
        }

        draft.Draft = false;
        await _context.SaveChangesAsync();
        return RedirectToPage("/Index");
    }

    public class SubmitPostModel
    {
        public int DraftId { get; set; }
        public string Title { get; set; } = "";
        public string? Permalink { get; set; }
    }
}