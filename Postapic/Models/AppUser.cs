namespace Postapic.Models;

public class AppUser
{
    public int Id { get; set; }
    public string Username { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;
    public bool IsAdmin { get; set; }

    public ICollection<Post> Posts { get; set; } = new List<Post>();
}