using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Postapic.Extensions;
using Postapic.Models;
using Postapic.Models.Enums;
using Postapic.Utils;
using SixLabors.ImageSharp.Formats.Gif;
using Upload.Core;

namespace Postapic.Pages;

public class PostPage : PageModel
{
    private readonly DataContext _context;
    private readonly StorageManager _storageManager;
    private readonly IOptions<AppConfig> _appConfig;
    private readonly Size _maxSize;

    public PostPage(DataContext context, StorageManager storageManager, IOptions<AppConfig> appConfig)
    {
        _context = context;
        _storageManager = storageManager;
        _appConfig = appConfig;
        _maxSize = new Size(_appConfig.Value.MediaConfig.MaxWidth, _appConfig.Value.MediaConfig.MaxHeight);
    }
    
    [BindProperty] public SubmitPostModel SubmitPostDto { get; set; }
    
    public Post DraftPost { get; set; }

    public async Task<ActionResult> OnPostCreateDraftAsync()
    {
        var userId = User.GetUserId(_appConfig.Value);
        if (userId is null) return Page();
        
        if (Request.Form.Files.Count == 0) RedirectToPage("/Index");;
        
        List<Media> medias = new();
        foreach (var formFile in Request.Form.Files)
        {
            await using var stream = formFile.OpenReadStream();
            using var image = await Image.LoadAsync(stream);
            {
                image.Mutate(i => i.Resize(new ResizeOptions
                {
                    Mode = ResizeMode.Max,
                    Size = _maxSize
                }).AutoOrient());
                
                var output = new MemoryStream();
                // Don't convert GIFs to webp format, just copy
                if (image.Metadata.DecodedImageFormat == GifFormat.Instance)
                {
                    // TODO: Resize do not mutate GIFs because we use original stream. SaveAsGif distorts GIF itself
                    stream.Position = 0;
                    await stream.CopyToAsync(output);
                }
                else
                {
                    await image.SaveAsWebpAsync(output);
                }
                
                output.Position = 0;
                var now = DateTime.UtcNow;
                var fileName = $"{now.Year}/{now.Month}/{now:yyyy-MM-ddThh-mm-ss}-{Random.Shared.Next(10, 100)}.webp";
                var fileRef = await _storageManager.CreateFile("primary", fileName, output);

                medias.Add(new Media
                {
                    Key = $"/media/{fileRef.Key}",
                    Height = image.Height,
                    Width = image.Width,
                    Type = MediaType.Image
                });
            }
        }

        var draftPost = new Post
        {
            Medias = medias,
            Permalink = $"DRAFT-{Random.Shared.Next(100, 1000)}",
            Timestamp = DateTime.UtcNow,
            Title = "DRAFT",
            UserId = (int)userId,
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
        
        draft.Permalink = null;
        if (!string.IsNullOrEmpty(SubmitPostDto.Permalink?.Trim()))
        {
            if (int.TryParse(SubmitPostDto.Permalink.Trim(), out var _))
            {
                ViewData["error-msg"] = "Permalink can't be a number. Please change and publish again";
                draft.Permalink = string.Empty;
                DraftPost = draft;
                return Page();
            }
            
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

        draft.Title = SubmitPostDto.Title;
        draft.Timestamp = DateTime.UtcNow;
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