using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public NotificationsController(AppDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET: api/Notifications
        // Get current user's notifications only
        // ============================================================

        [HttpGet]
        public async Task<IActionResult> GetNotifications()
        {
            var userIdClaim =
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

           var organizationIdClaim =
               User.FindFirst("OrganizationId")?.Value;

            if (!int.TryParse(userIdClaim, out var userId) ||
                !int.TryParse(organizationIdClaim, out var organizationId))
            {
                return Unauthorized("User information is missing.");
            }

            var notifications = await _context.Notifications
                .Where(notification =>
                    notification.UserId == userId &&
                    notification.OrganizationId == organizationId)
                .OrderByDescending(notification => notification.CreatedAt)
                .ToListAsync();

            return Ok(notifications);
        }

        // ============================================================
        // PUT: api/Notifications/{id}/read
        // Mark one notification as read
        // ============================================================

        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userIdClaim =
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

           var organizationIdClaim =
               User.FindFirst("OrganizationId")?.Value;

            if (!int.TryParse(userIdClaim, out var userId) ||
                !int.TryParse(organizationIdClaim, out var organizationId))
            {
                return Unauthorized("User information is missing.");
            }

            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n =>
                    n.Id == id &&
                    n.UserId == userId &&
                    n.OrganizationId == organizationId);

            if (notification == null)
            {
                return NotFound("Notification not found.");
            }

            notification.IsRead = true;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Notification marked as read."
            });
        }

        // ============================================================
        // PUT: api/Notifications/read-all
        // Mark all current user's notifications as read
        // ============================================================

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userIdClaim =
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

           var organizationIdClaim =
               User.FindFirst("OrganizationId")?.Value;

            if (!int.TryParse(userIdClaim, out var userId) ||
                !int.TryParse(organizationIdClaim, out var organizationId))
            {
                return Unauthorized("User information is missing.");
            }

            var notifications = await _context.Notifications
                .Where(notification =>
                    notification.UserId == userId &&
                    notification.OrganizationId == organizationId &&
                    !notification.IsRead)
                .ToListAsync();

            foreach (var notification in notifications)
            {
                notification.IsRead = true;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "All notifications marked as read."
            });
        }
    }
}