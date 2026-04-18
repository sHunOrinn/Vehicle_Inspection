using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using PayOS;
using Vehicle_Inspection.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

// Register VehInsContext with dependency injection
builder.Services.AddDbContext<VehInsContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("VehicleDb")));

builder.Services.AddControllersWithViews()
    .AddDataAnnotationsLocalization();

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(options =>
{
    options.LoginPath = "/Account/Login"; // Đường dẫn đến trang đăng nhập
    options.LogoutPath = "/Account/Logout"; // Đường dẫn đến trang đăng xuất
    options.AccessDeniedPath = "/Account/AccessDenied"; // Đường dẫn khi truy cập bị từ chối
    options.ExpireTimeSpan = TimeSpan.FromMinutes(30); // Thời gian hết hạn cookie
    options.SlidingExpiration = true;
    options.Cookie.Name = "VehicleInspectionAuth";
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
});


// Đăng ký tất cả service trong namespace Vehicle_Inspection.Service
var adminAssembly = typeof(Vehicle_Inspection.Controllers.HomeController).Assembly;
builder.Services.Scan(scan => scan
    .FromAssemblies(adminAssembly)
        .AddClasses(classes => classes.InNamespaces("Vehicle_Inspection.Service"))
        .AsImplementedInterfaces()
        .WithScopedLifetime());


builder.Services.AddSingleton(sp =>
{
    var cfg = sp.GetRequiredService<IConfiguration>();

    var clientId = cfg["PayOS:ClientId"];
    var apiKey = cfg["PayOS:ApiKey"];
    var checksumKey = cfg["PayOS:ChecksumKey"];

    if (string.IsNullOrWhiteSpace(clientId) ||
        string.IsNullOrWhiteSpace(apiKey) ||
        string.IsNullOrWhiteSpace(checksumKey))
    {
        throw new InvalidOperationException("Thiếu cấu hình PayOS:ClientId/ApiKey/ChecksumKey trong appsettings.json (hoặc User Secrets).");
    }

    return new PayOSClient(clientId, apiKey, checksumKey);
});




var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
