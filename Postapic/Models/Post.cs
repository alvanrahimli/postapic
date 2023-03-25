namespace Postapic.Models;

public class Post
{
    public int Id { get; set; }
    public string Permalink { get; set; } = null!;
    public string Title { get; set; } = null!;
    public DateTime Timestamp { get; set; }

    public int UserId { get; set; }
    public AppUser User { get; set; } = null!;

    public ICollection<Media> Medias { get; set; } = new List<Media>();
}