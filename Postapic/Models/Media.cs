using Postapic.Models.Enums;

namespace Postapic.Models;

public class Media
{
    public int Id { get; set; }
    public string Key { get; set; } = null!;
    
    public MediaType Type { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }

    public int PostId { get; set; }
    public Post Post { get; set; } = null!;
}