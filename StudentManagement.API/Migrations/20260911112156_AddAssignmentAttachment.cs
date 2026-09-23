using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentManagement.API.Migrations
{
    /// <inheritdoc />
    public partial class AddAssignmentAttachment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AttachmentFileName",
                table: "Assignments",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AttachmentFilePath",
                table: "Assignments",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AttachmentFileName",
                table: "Assignments");

            migrationBuilder.DropColumn(
                name: "AttachmentFilePath",
                table: "Assignments");
        }
    }
}
