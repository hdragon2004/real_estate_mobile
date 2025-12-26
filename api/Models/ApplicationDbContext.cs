using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Model
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        { }

        public DbSet<City> Cities { get; set; }
        public DbSet<District> Districts { get; set; }
        public DbSet<Ward> Wards { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Post> Posts { get; set; }
        public DbSet<PostImage> PostImages { get; set; }
        public DbSet<Report> Reports { get; set; }
        public DbSet<Message> Messages { get; set; }
        public DbSet<Favorite> Favorites { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<SavedSearch> SavedSearches { get; set; }
        public DbSet<Appointment> Appointments { get; set; }
        

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<PostImage>()
                .HasOne(pi => pi.Post)
                .WithMany(p => p.Images)
                .HasForeignKey(pi => pi.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Post>()
                .HasOne(p => p.Category)
                .WithMany()
                .HasForeignKey(p => p.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Post>()
                .HasOne(p => p.User)
                .WithMany()
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Post>()
                .Property(p => p.Price)
                .HasPrecision(18, 2);

            modelBuilder.Entity<User>()
                .Property(u => u.Role)
                .HasConversion<string>();

            modelBuilder.Entity<Report>()
                .Property(r => r.Type)
                .HasConversion<int>();

            modelBuilder.Entity<Post>()
                .Property(p => p.TransactionType)
                .HasConversion<int>();


            modelBuilder.Entity<Post>()
                .Property(p => p.Status)
                .HasDefaultValue("Pending")
                .IsRequired(false);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Sender)
                .WithMany()
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Receiver)
                .WithMany()
                .HasForeignKey(m => m.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Post)
                .WithMany(p => p.Messages)
                .HasForeignKey(m => m.PostId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Favorite>()
                .HasOne(f => f.User)
                .WithMany()
                .HasForeignKey(f => f.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Favorite>()
                .HasOne(f => f.Post)
                .WithMany()
                .HasForeignKey(f => f.PostId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Report>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Report>()
                .HasOne(r => r.Post)
                .WithMany()
                .HasForeignKey(r => r.PostId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.Post)
                .WithMany()
                .HasForeignKey(n => n.PostId)
                .OnDelete(DeleteBehavior.Restrict);

            // SavedSearchId trong Notification là metadata, không phải FK

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.Appointment)
                .WithMany()
                .HasForeignKey(n => n.AppointmentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.MessageEntity)
                .WithMany()
                .HasForeignKey(n => n.MessageId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<SavedSearch>()
                .HasOne(ss => ss.User)
                .WithMany()
                .HasForeignKey(ss => ss.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<SavedSearch>()
                .Property(ss => ss.TransactionType)
                .HasConversion<int>();

            modelBuilder.Entity<SavedSearch>()
                .Property(ss => ss.MinPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<SavedSearch>()
                .Property(ss => ss.MaxPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.User)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.Post)
                .WithMany()
                .HasForeignKey(a => a.PostId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<District>()
                .HasOne(d => d.City)
                .WithMany()
                .HasForeignKey(d => d.CityId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Ward>()
                .HasOne(w => w.District)
                .WithMany()
                .HasForeignKey(w => w.DistrictId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}