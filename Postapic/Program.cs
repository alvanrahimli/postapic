using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Postapic.Models;
using Postapic.Utils;
using Upload.Core;
using Upload.Core.Browser;
using Upload.Disk;

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<AppConfig>(builder.Configuration.GetSection(AppConfig.ConfigName));
builder.Services.AddRazorPages(options =>
{
    options.Conventions.AuthorizePage("/LogOut");
    options.Conventions.AuthorizeFolder("/Settings");
    options.Conventions.AuthorizePage("/PostPage");
    
    if (Environment.GetEnvironmentVariable("AUTHORIZE_INDEX")?.ToUpper() == "TRUE")
    {
        options.Conventions.AuthorizePage("/Index");
        options.Conventions.AuthorizePage("/SinglePost");
    }

    options.Conventions.AllowAnonymousToPage("/Login");
});
builder.Services.AddHttpContextAccessor();
builder.Services.AddDbContext<DataContext>(options =>
{
    options.UseSqlite(builder.Configuration.GetConnectionString("Default"));
});

builder.Services.AddAuthorization();
if (builder.Configuration["AppConfig:AuthenticateWith"] == "cookie")
{
    builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
        .AddCookie(options =>
        {
            options.ExpireTimeSpan = TimeSpan.FromDays(28);
            options.LoginPath = "/login";
            options.LogoutPath = "/logout";
        });
}
else if (builder.Configuration["AppConfig:AuthenticateWith"] == "github.com/themisir/identity")
{
    var identitySection = builder.Configuration.GetSection("github.com/themisir/identity");
    builder.Services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.Authority = identitySection["Jwt:Issuer"];
            options.Audience = identitySection["Jwt:Audience"];
            options.RequireHttpsMetadata = false;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
            };
        });
}

builder.Services.AddUploadNet()
    .AddDiskProvider("primary", options =>
    {
        options.Browser = new DefaultStorageBrowser(builder.Configuration["UploadNet:UrlFormat"]);
        options.Directory = builder.Configuration["UploadNet:Directory"];
    });

var app = builder.Build();

// TODO: Create version based migration logic?
await using var scope = app.Services.CreateAsyncScope();
{
    var db = scope.ServiceProvider.GetRequiredService<DataContext>();
    await db.Database.MigrateAsync();
}

await Initialization.InitializeAdmin(app.Services);

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapRazorPages();
app.MapUploadedStaticFiles("/media", "primary");

app.Run();