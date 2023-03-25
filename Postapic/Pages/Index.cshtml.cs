using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Postapic.Models;

namespace Postapic.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly DataContext _context;

    public List<Post> Posts { get; set; } = new();

    public IndexModel(ILogger<IndexModel> logger, DataContext context)
    {
        _logger = logger;
        _context = context;
    }

    public async Task OnGetAsync()
    {
        Posts = await _context.Posts.AsNoTracking()
            .Include(p => p.Medias)
            .Include(p => p.User)
            .ToListAsync();
    }
}

public class HMSFormatter:ICustomFormatter, IFormatProvider
{
    // list of Formats, with a P customformat for pluralization
    static Dictionary<string, string> timeformats = new Dictionary<string, string> {
        {"S", "{0:P:Seconds:Second}"},
        {"M", "{0:P:Minutes:Minute}"},
        {"H","{0:P:Hours:Hour}"},
        {"D", "{0:P:Days:Day}"}
    };

    public string Format(string format, object arg, IFormatProvider formatProvider)
    {
        return String.Format(new PluralFormatter(),timeformats[format], arg);
    }

    public object GetFormat(Type formatType)
    {
        return formatType == typeof(ICustomFormatter)?this:null;
    }   
}

// formats a numeric value based on a format P:Plural:Singular
public class PluralFormatter:ICustomFormatter, IFormatProvider
{

    public string Format(string format, object arg, IFormatProvider formatProvider)
    {
        if (arg !=null)
        {
            var parts = format.Split(':'); // ["P", "Plural", "Singular"]

            if (parts[0] == "P") // correct format?
            {
                // which index postion to use
                int partIndex = (arg.ToString() == "1")?2:1;
                // pick string (safe guard for array bounds) and format
                return String.Format("{0} {1}", arg, (parts.Length>partIndex?parts[partIndex]:""));               
            }
        }
        return String.Format(format, arg);
    }

    public object GetFormat(Type formatType)
    {
        return formatType == typeof(ICustomFormatter)?this:null;
    }   
}