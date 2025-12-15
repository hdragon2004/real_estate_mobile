using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;
using RealEstateHubAPI.Repositories;
using RealEstateHubAPI.Services;
using RealEstateHubAPI.seeds;
using System;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

var builder = WebApplication.CreateBuilder(args);

// Add DbContext
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add repositories & services
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<ILocationRepository, LocationRepository>();
builder.Services.AddScoped<IPostRepository, PostRepository>();
builder.Services.AddScoped<IPostService, PostService>();
builder.Services.AddScoped<ISavedSearchService, SavedSearchService>();
builder.Services.AddScoped<IAppointmentService, AppointmentService>();

// Add Google Places mapping service
builder.Services.AddScoped<IGooglePlacesMappingService, GooglePlacesMappingService>();

//Add VnPay service
builder.Services.AddScoped<IVNPayService, VNPayService>();
builder.Services.AddScoped<IPaymentProcessingService, PaymentProcessingService>();

//Add Momo service
builder.Services.Configure<MomoOptionModel>(builder.Configuration.GetSection("MomoAPI"));
builder.Services.AddScoped<IMomoService, MomoService>();

//Add Chat service
builder.Services.AddScoped<IChatService, ChatService>();


//builder.Services.AddScoped<IReportRepository, ReportRepository>();

builder.Services.AddScoped<IAuthService, AuthService>();

// Add JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"];
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
        
        // Cấu hình JWT cho SignalR
        // SignalR gửi token qua query string hoặc header "Authorization"
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                // Lấy token từ query string (SignalR WebSocket không hỗ trợ headers)
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                
                // Chỉ áp dụng cho SignalR hubs
                if (!string.IsNullOrEmpty(accessToken) && 
                    (path.StartsWithSegments("/messageHub") || path.StartsWithSegments("/notificationHub")))
                {
                    context.Token = accessToken;
                }
                
                return Task.CompletedTask;
            }
        };
    });


builder.Services.AddAuthorization();

// Add Controllers with increased file size limit for large images
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Cho phép parse string thành enum (ví dụ: "Sale" -> TransactionType.Sale)
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
        // Cho phép parse camelCase JSON thành PascalCase properties
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });

// Configure form options for large file uploads (images can be 10-20MB each)
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 524288000; // 500 MB total
    options.ValueLengthLimit = 524288000;
    options.MultipartHeadersLengthLimit = 524288000;
});

// Configure Kestrel server limits
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.Limits.MaxRequestBodySize = 524288000; // 500 MB
    serverOptions.Limits.RequestHeadersTimeout = TimeSpan.FromMinutes(5);
});

builder.Services.AddHttpClient();
// Configure SignalR với JWT authentication
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true; // Chỉ bật trong development
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddMemoryCache();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Real Estate Hub API",
        Version = "v1"
    });


    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,

    });


    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// AI text generation service
builder.Services.AddHttpClient(nameof(OpenAiTextService), client =>
{
    client.Timeout = TimeSpan.FromSeconds(120); // Increase timeout for AI
});
builder.Services.AddScoped<IAiTextService, OpenAiTextService>();

// OpenStreetMap amenity service - optimized with shorter timeout
builder.Services.AddHttpClient(nameof(OpenStreetMapAmenityService), client =>
{
    client.Timeout = TimeSpan.FromSeconds(15); // Reduce timeout to avoid blocking
});
builder.Services.AddScoped<IAmenityLookupService, OpenStreetMapAmenityService>();


// Add CORS
builder.Services.AddCors(options =>
{
    // Policy cho phép tất cả origins trong development (để test Flutter web dễ dàng)
    // Bao gồm cả localhost và ngrok domains
    if (builder.Environment.IsDevelopment())
    {
        options.AddPolicy("AllowAll",
            policy =>
            {
                policy.SetIsOriginAllowed(origin =>
                {
                    // Cho phép tất cả localhost với mọi port
                    if (string.IsNullOrEmpty(origin)) return false;
                    try
                    {
                        var uri = new Uri(origin);
                        // Cho phép localhost, 127.0.0.1, và ngrok domains
                        return uri.Host == "localhost" 
                            || uri.Host == "127.0.0.1"
                            || uri.Host.EndsWith(".ngrok-free.dev")
                            || uri.Host.EndsWith(".ngrok.io");
                    }
                    catch
                    {
                        return false;
                    }
                })
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
            });
    }
    
    // Policy cho production - chỉ cho phép frontend cụ thể
    options.AddPolicy("AllowFrontend",
        policy =>
        {
            policy.WithOrigins("http://localhost:5173")  // React frontend
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        });
});

builder.Services.AddHostedService<ExpireNotificationService>();
builder.Services.AddHostedService<AppointmentReminderService>();


var app = builder.Build();





// Middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// CORS phải được đặt TRƯỚC UseHttpsRedirection và các middleware khác
if (app.Environment.IsDevelopment())
{
    app.UseCors("AllowAll"); // Cho phép tất cả trong development
}
else
{
    app.UseCors("AllowFrontend"); // Chỉ cho phép frontend cụ thể trong production
}

app.UseHttpsRedirection();

// Configure static files
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Map SignalR Hubs
app.MapHub<RealEstateHubAPI.Hubs.NotificationHub>("/notificationHub");
app.MapHub<RealEstateHubAPI.Hubs.MessageHub>("/messageHub");

// Seed data on startup - CHỈ seed khi database trống (không reset data hiện có)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        // Chỉ seed khi database trống, không force để giữ data hiện có
        DataSeeder.SeedData(context, force: false);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while seeding the database.");
    }
}

app.Run();
