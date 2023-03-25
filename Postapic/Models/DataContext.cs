using Microsoft.EntityFrameworkCore;

namespace Postapic.Models;

public class DataContext : DbContext
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<Media> Medias => Set<Media>();

    public DataContext(DbContextOptions<DataContext> options) : base(options)
    {
        
    }
}